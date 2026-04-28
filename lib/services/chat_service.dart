import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

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
    final user = _auth.currentUser!;
    final chatId = _buildChatId(user.uid, receiverId);
    final senderDoc = await _firestore.collection('users').doc(user.uid).get();
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
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromDocument(doc)).toList(),
        );
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
    await _firestore.collection('messages').doc(messageId).delete();
  }
}
