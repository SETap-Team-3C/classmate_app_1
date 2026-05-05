import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';
import '../core/utils/error_handler.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _buildChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage(String receiverId, String message) async {
    try {
      final user = _auth.currentUser!;
      final chatId = _buildChatId(user.uid, receiverId);
      final senderDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final senderName = (senderDoc.data()?['name'] ?? user.displayName ?? '')
          .toString();
      final receiverName = (receiverDoc.data()?['name'] ?? '').toString();

      final batch = _firestore.batch();
      final messageDoc = _firestore.collection('messages').doc();
      final chatDoc = _firestore.collection('chats').doc(chatId);
      final messageData = Message(
        id: messageDoc.id,
        chatId: chatId,
        senderId: user.uid,
        receiverId: receiverId,
        text: message,
      ).toCreateMap();

      batch.set(messageDoc, messageData);

      batch.set(chatDoc, {
        'participants': [user.uid, receiverId],
        'usernames': {user.uid: senderName, receiverId: receiverName},
        'lastMessage': message,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      ErrorHandler.logError(e, context: 'sendMessage');
      rethrow;
    }
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

    return _firestore
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final all = snapshot.docs
              .map((doc) => Message.fromDocument(doc))
              .toList();
          return all
              .where((m) => !(m.deletedFor?.contains(userId) ?? false))
              .toList();
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
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isDeleted': true,
        'text': '[This message was deleted]',
      });
    } catch (e) {
      ErrorHandler.logError(e, context: 'deleteMessage');
      rethrow;
    }
  }

  Future<void> deleteMessageForMe(String messageId, String userId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      ErrorHandler.logError(e, context: 'deleteMessageForMe');
      rethrow;
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
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
      final docRef = _firestore.collection('messages').doc(messageId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final current = data?['starredBy'] is List
          ? List<String>.from(
              (data!['starredBy'] as List).map((e) => e.toString()),
            )
          : <String>[];

      if (current.contains(userId)) {
        await docRef.update({
          'starredBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'starredBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
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
}
