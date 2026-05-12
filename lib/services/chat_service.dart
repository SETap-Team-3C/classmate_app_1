import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message.dart';
import '../core/utils/error_handler.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _storage = FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String _buildChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<User?> _waitForAuth({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser;

    try {
      return await _auth
          .authStateChanges()
          .where((user) => user != null)
          .cast<User>()
          .first
          .timeout(timeout);
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Future<void> sendMessage(String receiverId, String message) async {
    return sendTextMessage(receiverId, message);
  }

  Future<void> sendTextMessage(String receiverId, String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    try {
      final prepared = await _prepareMessageContext(receiverId);
      await _ensureChatDocument(
        chatId: prepared.chatId,
        senderUid: prepared.user.uid,
        receiverId: receiverId,
        senderName: prepared.senderName,
        receiverName: prepared.receiverName,
      );
      final messageDoc = _firestore.collection('messages').doc();
      final messageModel = Message(
        id: messageDoc.id,
        chatId: prepared.chatId,
        senderId: prepared.user.uid,
        receiverId: receiverId,
        messageType: MessageType.text,
        text: trimmed,
      );

      await _commitMessage(
        messageDoc: messageDoc,
        message: messageModel,
        chatId: prepared.chatId,
        senderUid: prepared.user.uid,
        receiverId: receiverId,
        senderName: prepared.senderName,
        receiverName: prepared.receiverName,
      );
    } catch (e) {
      ErrorHandler.logError(e, context: 'sendMessage');
      rethrow;
    }
  }

  Future<void> sendImageMessage(
    String receiverId,
    XFile imageFile, {
    String caption = '',
    ValueChanged<double>? onUploadProgress,
  }) async {
    UploadTask? uploadTask;
    Reference? storageRef;
    StreamSubscription<TaskSnapshot>? uploadSubscription;

    try {
      final prepared = await _prepareMessageContext(receiverId);
      await _ensureChatDocument(
        chatId: prepared.chatId,
        senderUid: prepared.user.uid,
        receiverId: receiverId,
        senderName: prepared.senderName,
        receiverName: prepared.receiverName,
      );
      debugPrint(
        '[sendImageMessage] ensured chat doc exists for ${prepared.chatId}',
      );

      final messageDoc = _firestore.collection('messages').doc();
      // Read bytes with error handling
      late List<int> bytes;
      try {
        bytes = await imageFile.readAsBytes();
      } catch (e) {
        debugPrint('[sendImageMessage] Error reading file bytes: $e');
        throw Exception('Failed to read image file. Please try another image.');
      }

      // Validate file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(
          'Image is too large. Please use an image smaller than 5MB.',
        );
      }
      final safeName = _sanitizeFileName(
        imageFile.name.isNotEmpty
            ? imageFile.name
            : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final contentType = _inferImageContentType(safeName);

      debugPrint(
        '[sendImageMessage] start: chatId=${prepared.chatId}, receiver=$receiverId, '
        'file=$safeName, bytes=${bytes.length}, contentType=$contentType',
      );

      final storagePath =
          'chat_uploads/${prepared.chatId}/${messageDoc.id}/$safeName';
      storageRef = _storage.ref(storagePath);
      debugPrint('[sendImageMessage] uploading to: $storagePath');

      uploadTask = storageRef.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );

      uploadSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (onUploadProgress != null && snapshot.totalBytes > 0) {
          onUploadProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }

        if (snapshot.totalBytes > 0) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes * 100)
                  .toStringAsFixed(1);
          debugPrint(
            '[sendImageMessage] upload progress: $progress% '
            '(${snapshot.bytesTransferred}/${snapshot.totalBytes})',
          );
        }
      });

      await uploadTask;
      debugPrint('[sendImageMessage] upload complete');

      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('[sendImageMessage] download URL generated: $downloadUrl');

      final messageModel = Message(
        id: messageDoc.id,
        chatId: prepared.chatId,
        senderId: prepared.user.uid,
        receiverId: receiverId,
        messageType: MessageType.image,
        text: caption.trim(),
        fileUrl: downloadUrl,
        fileName: safeName,
        mimeType: contentType,
        fileSize: bytes.length,
      );

      debugPrint('[sendImageMessage] writing message doc: ${messageDoc.id}');
      await _commitMessage(
        messageDoc: messageDoc,
        message: messageModel,
        chatId: prepared.chatId,
        senderUid: prepared.user.uid,
        receiverId: receiverId,
        senderName: prepared.senderName,
        receiverName: prepared.receiverName,
      );
      debugPrint('[sendImageMessage] firestore write complete');
    } catch (e) {
      debugPrint('[sendImageMessage] ERROR: $e');
      debugPrint('[sendImageMessage] ERROR type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint(
          '[sendImageMessage] FirebaseException code=${e.code}, message=${e.message}, plugin=${e.plugin}',
        );
      }
      if (storageRef != null) {
        try {
          await storageRef.delete();
          debugPrint(
            '[sendImageMessage] cleaned up failed upload: ${storageRef.fullPath}',
          );
        } catch (_) {
          // Ignore cleanup errors.
        }
      }
      ErrorHandler.logError(e, context: 'sendImageMessage');
      rethrow;
    } finally {
      await uploadSubscription?.cancel();
    }
  }

  Future<void> _ensureChatDocument({
    required String chatId,
    required String senderUid,
    required String receiverId,
    required String senderName,
    required String receiverName,
  }) async {
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderUid, receiverId],
      'usernames': {senderUid: senderName, receiverId: receiverName},
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<_MessageContext> _prepareMessageContext(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to send messages.',
      );
    }

    final chatId = _buildChatId(user.uid, receiverId);
    final senderDoc = await _firestore.collection('users').doc(user.uid).get();
    final receiverDoc = await _firestore
        .collection('users')
        .doc(receiverId)
        .get();
    final senderName = (senderDoc.data()?['name'] ?? user.displayName ?? '')
        .toString();
    final receiverName = (receiverDoc.data()?['name'] ?? '').toString();

    return _MessageContext(
      user: user,
      chatId: chatId,
      senderName: senderName,
      receiverName: receiverName,
    );
  }

  Future<void> _commitMessage({
    required DocumentReference<Map<String, dynamic>> messageDoc,
    required Message message,
    required String chatId,
    required String senderUid,
    required String receiverId,
    required String senderName,
    required String receiverName,
  }) async {
    final batch = _firestore.batch();
    batch.set(messageDoc, message.toCreateMap());
    batch.set(_firestore.collection('chats').doc(chatId), {
      'participants': [senderUid, receiverId],
      'usernames': {senderUid: senderName, receiverId: receiverName},
      'lastMessage': message.previewText,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('[commitMessage] ERROR: $e');
      debugPrint('[commitMessage] ERROR type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint(
          '[commitMessage] FirebaseException code=${e.code}, message=${e.message}, plugin=${e.plugin}',
        );
      }
      rethrow;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _inferImageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Future<void> markMessageAsRead(String messageId, String readBy) async {
    await _firestore.collection('messages').doc(messageId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
      'readBy': readBy,
    });
  }

  Stream<List<Message>> getMessages(String userId, String otherUserId) {
    final chatId = _buildChatId(userId, otherUserId);

    return Stream<List<Message>>.multi((controller) {
      final sentMessagesById = <String, Message>{};
      final receivedMessagesById = <String, Message>{};
      Set<String> hiddenMessageIds = <String>{};

      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sentSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? receivedSub;
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;

      void emit() {
        final merged = <String, Message>{}
          ..addAll(sentMessagesById)
          ..addAll(receivedMessagesById);

        final visible = merged.values.where(
          (message) =>
              !(message.deletedFor?.contains(userId) ?? false) &&
              !hiddenMessageIds.contains(message.id),
        );

        final deduped = visible.toList()
          ..sort((a, b) {
            final aMillis = a.timestamp?.millisecondsSinceEpoch ?? 0;
            final bMillis = b.timestamp?.millisecondsSinceEpoch ?? 0;
            return bMillis.compareTo(aMillis);
          });

        controller.add(deduped);
      }

      sentSub = _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
            sentMessagesById
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (doc) => MapEntry(doc.id, Message.fromDocument(doc)),
                ),
              );
            emit();
          }, onError: controller.addError);

      receivedSub = _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
            receivedMessagesById
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (doc) => MapEntry(doc.id, Message.fromDocument(doc)),
                ),
              );
            emit();
          }, onError: controller.addError);

      userSub = _firestore.collection('users').doc(userId).snapshots().listen((
        snapshot,
      ) {
        final data = snapshot.data();
        final hiddenIds = data?['hiddenMessageIds'];
        hiddenMessageIds = hiddenIds is List
            ? hiddenIds.map((value) => value.toString()).toSet()
            : <String>{};
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await sentSub?.cancel();
        await receivedSub?.cancel();
        await userSub?.cancel();
      };
    });
  }

  Future<int> getUnreadCount(String chatId, String currentUserId) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> deleteMessage(String messageId) async {
    debugPrint('🚨 deleteMessage CALLED for id=$messageId');

    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to delete messages.',
      );
    }

    final docRef = _firestore.collection('messages').doc(messageId);
    try {
      debugPrint(
        '[deleteMessage] Reading message doc to verify ownership: $messageId',
      );
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        debugPrint('[deleteMessage] ❌ Message not found: $messageId');
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Message not found',
        );
      }

      final data = snapshot.data();
      final senderId = data?['senderId']?.toString();

      if (senderId != user.uid) {
        debugPrint(
          '[deleteMessage] ❌ Current user (${user.uid}) is not the sender ($senderId)',
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Only the sender can delete this message for everyone.',
        );
      }

      debugPrint(
        '[deleteMessage] Marking message as deleted for everyone: $messageId',
      );
      await docRef.update({
        'isDeleted': true,
        'text': '[This message was deleted]',
      });
      debugPrint(
        '[deleteMessage] ✅ Successfully marked message deleted: $messageId',
      );
    } catch (e) {
      debugPrint('[deleteMessage] ❌ Error deleting for everyone: $e');
      ErrorHandler.logError(e, context: 'deleteMessage');
      rethrow;
    }
  }

  Future<void> deleteMessageForMe(String messageId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to delete messages.',
      );
    }

    final docRef = _firestore.collection('messages').doc(messageId);
    try {
      debugPrint(
        '[deleteMessageForMe] Attempting to delete for user: $userId, message: $messageId',
      );
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        debugPrint('[deleteMessageForMe] ❌ Message not found: $messageId');
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Message not found',
        );
      }

      final data = snapshot.data();
      final senderId = data?['senderId']?.toString();
      final receiverId = data?['receiverId']?.toString();

      if (user.uid != senderId && user.uid != receiverId) {
        debugPrint(
          '[deleteMessageForMe] ❌ User ${user.uid} is not a participant (sender: $senderId, receiver: $receiverId)',
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Only chat participants can delete messages for themselves.',
        );
      }

      await _firestore.collection('users').doc(user.uid).set({
        'hiddenMessageIds': FieldValue.arrayUnion([messageId]),
      }, SetOptions(merge: true));
      debugPrint('[deleteMessageForMe] ✅ Successfully deleted for me');
    } on FirebaseException catch (fe) {
      debugPrint(
        '[deleteMessageForMe] ❌ FirebaseException: code=${fe.code}, message=${fe.message}',
      );
      ErrorHandler.logError(fe, context: 'deleteMessageForMe');
      rethrow;
    } catch (e) {
      debugPrint('[deleteMessageForMe] ❌ Error deleting for me: $e');
      ErrorHandler.logError(e, context: 'deleteMessageForMe');
      rethrow;
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    final user = _auth.currentUser ?? await _waitForAuth();
    if (user == null) {
      debugPrint('[editMessage] auth not ready, skipping edit');
      return;
    }

    try {
      await _firestore.collection('messages').doc(messageId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ErrorHandler.logError(e, context: 'editMessage');
      rethrow;
    }
  }

  Future<void> toggleStar(String messageId, String userId) async {
    try {
      debugPrint(
        '[toggleStar] Attempting to toggle star for message: $messageId, user: $userId',
      );
      final docRef = _firestore.collection('messages').doc(messageId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        debugPrint('[toggleStar] ❌ Message does not exist: $messageId');
        return;
      }

      final data = snapshot.data();
      final current = data?['starredBy'] is List
          ? List<String>.from(
              (data!['starredBy'] as List).map((e) => e.toString()),
            )
          : <String>[];

      if (current.contains(userId)) {
        debugPrint('[toggleStar] Removing star from message');
        await docRef.update({
          'starredBy': FieldValue.arrayRemove([userId]),
        });
        debugPrint('[toggleStar] ✅ Star removed');
      } else {
        debugPrint('[toggleStar] Adding star to message');
        await docRef.update({
          'starredBy': FieldValue.arrayUnion([userId]),
        });
        debugPrint('[toggleStar] ✅ Star added');
      }
    } on FirebaseException catch (fe) {
      debugPrint(
        '[toggleStar] ❌ FirebaseException: code=${fe.code}, message=${fe.message}',
      );
      ErrorHandler.logError(fe, context: 'toggleStar');
      rethrow;
    } catch (e) {
      debugPrint('[toggleStar] ❌ Error toggling star: $e');
      ErrorHandler.logError(e, context: 'toggleStar');
      rethrow;
    }
  }

  Stream<List<Message>> getStarredMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('starredBy', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromDocument(d)).toList());
  }

  Future<List<Message>> searchMessagesInChat(
    String userId,
    String otherUserId,
    String query,
  ) async {
    if (query.isEmpty) return [];

    final chatId = _buildChatId(userId, otherUserId);
    final sentSnapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('senderId', isEqualTo: userId)
        .get();
    final receivedSnapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .get();

    final byId = <String, Message>{};
    for (final doc in sentSnapshot.docs) {
      byId[doc.id] = Message.fromDocument(doc);
    }
    for (final doc in receivedSnapshot.docs) {
      byId[doc.id] = Message.fromDocument(doc);
    }

    final allMessages = byId.values.toList();

    // Filter by search query (case-insensitive)
    final filtered = allMessages
        .where(
          (m) =>
              m.text.toLowerCase().contains(query.toLowerCase()) &&
              !(m.deletedFor?.contains(userId) ?? false),
        )
        .toList();

    // Sort by timestamp descending
    filtered.sort((a, b) {
      final aMillis = a.timestamp?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.timestamp?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });

    return filtered;
  }

  // Set user online status
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ChatService] Error setting online status: $e');
    }
  }

  // Get user online status stream
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) => snap.data()?['isOnline'] as bool? ?? false);
  }

  // Toggle reaction on a message
  Future<void> toggleReaction(
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      final docRef = _firestore.collection('messages').doc(messageId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final reactions = data?['reactions'] is Map
          ? Map<String, dynamic>.from(data!['reactions'] as Map)
          : <String, dynamic>{};

      final reactionUsers = reactions[emoji] is List
          ? List<String>.from(
              (reactions[emoji] as List).map((e) => e.toString()),
            )
          : <String>[];

      if (reactionUsers.contains(userId)) {
        reactionUsers.remove(userId);
        if (reactionUsers.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = reactionUsers;
        }
      } else {
        reactionUsers.add(userId);
        reactions[emoji] = reactionUsers;
      }

      await docRef.update({'reactions': reactions.isEmpty ? null : reactions});
    } catch (e) {
      debugPrint('[ChatService] Error toggling reaction: $e');
    }
  }

  // Get last seen time formatted for display
  Future<String> getLastSeenDisplay(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final lastSeen = snapshot.data()?['lastSeen'] as Timestamp?;
      if (lastSeen == null) return 'never';

      final now = DateTime.now();
      final diff = now.difference(lastSeen.toDate());

      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return 'a week ago';
    } catch (e) {
      debugPrint('[ChatService] Error getting last seen: $e');
      return 'unknown';
    }
  }

  // Get unread message count for a specific chat
  Future<int> getUnreadCountForChat(String chatId, String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[ChatService] Error getting unread count: $e');
      return 0;
    }
  }

  // Get user-friendly error message
  String getUserFriendlyError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action.';
        case 'not-found':
          return 'The conversation or message was not found.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again.';
        case 'network-error':
          return 'Network error. Please check your connection.';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

class _MessageContext {
  _MessageContext({
    required this.user,
    required this.chatId,
    required this.senderName,
    required this.receiverName,
  });

  final User user;
  final String chatId;
  final String senderName;
  final String receiverName;
}
