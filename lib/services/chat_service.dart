import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _buildChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage(
    String receiverId,
    String message,
  ) async {
    final user = _auth.currentUser!;
    final chatId = _buildChatId(user.uid, receiverId);
    final senderDoc = await _firestore.collection('users').doc(user.uid).get();
    final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    final senderName =
        (senderDoc.data()?['name'] ?? user.displayName ?? '').toString();
    final receiverName = (receiverDoc.data()?['name'] ?? '').toString();

    final batch = _firestore.batch();
    final messageDoc = _firestore.collection('messages').doc();
    final chatDoc = _firestore.collection('chats').doc(chatId);

    batch.set(messageDoc, {
      'chatId': chatId,
      'senderId': user.uid,
      'receiverId': receiverId,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.set(chatDoc, {
      'participants': [user.uid, receiverId],
      'usernames': {
        user.uid: senderName,
        receiverId: receiverName,
      },
      'lastMessage': message,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<QuerySnapshot> getMessages(
    String userId,
    String otherUserId,
  ) {
    final chatId = _buildChatId(userId, otherUserId);

    return _firestore
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .orderBy("timestamp")
        .snapshots();
  }
}
