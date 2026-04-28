import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp? timestamp;
  final bool read;
  final Timestamp? readAt;
  final String? readBy;

  Message({
    this.id = '',
    this.chatId = '',
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.timestamp,
    this.read = false,
    this.readAt,
    this.readBy,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      receiverId: (data['receiverId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : null,
      read: data['read'] == true,
      readAt: data['readAt'] is Timestamp ? data['readAt'] as Timestamp : null,
      readBy: data['readBy']?.toString(),
    );
  }

  factory Message.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Message.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
      'readAt': readAt,
      'readBy': readBy,
    };
  }
}
