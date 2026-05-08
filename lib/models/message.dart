import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, document, contact }

MessageType _messageTypeFromString(String value) {
  switch (value) {
    case 'image':
      return MessageType.image;
    case 'document':
      return MessageType.document;
    case 'contact':
      return MessageType.contact;
    case 'text':
    default:
      return MessageType.text;
  }
}

extension MessageTypeX on MessageType {
  String get value => switch (this) {
    MessageType.text => 'text',
    MessageType.image => 'image',
    MessageType.document => 'document',
    MessageType.contact => 'contact',
  };
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final MessageType messageType;
  final String text;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final String? thumbnailUrl;
  final double? imageWidth;
  final double? imageHeight;
  final Map<String, dynamic>? contactData;
  final Timestamp? timestamp;
  final bool read;
  final Timestamp? readAt;
  final String? readBy;
  final Timestamp? editedAt;
  final bool isDeleted;
  final List<String>? starredBy;
  final List<String>? deletedFor;
  final Map<String, List<String>>?
  reactions; // e.g. {'👍': ['userId1', 'userId2']}
  final String? replyToId; // ID of message being replied to

  Message({
    this.id = '',
    this.chatId = '',
    required this.senderId,
    required this.receiverId,
    this.messageType = MessageType.text,
    required this.text,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.thumbnailUrl,
    this.imageWidth,
    this.imageHeight,
    this.contactData,
    this.timestamp,
    this.read = false,
    this.readAt,
    this.readBy,
    this.editedAt,
    this.isDeleted = false,
    this.starredBy,
    this.deletedFor,
    this.reactions,
    this.replyToId,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      receiverId: (data['receiverId'] ?? '').toString(),
      messageType: _messageTypeFromString(
        (data['messageType'] ?? 'text').toString(),
      ),
      text: (data['text'] ?? '').toString(),
      fileUrl: data['fileUrl']?.toString(),
      fileName: data['fileName']?.toString(),
      mimeType: data['mimeType']?.toString(),
      fileSize: data['fileSize'] is num
          ? (data['fileSize'] as num).toInt()
          : null,
      thumbnailUrl: data['thumbnailUrl']?.toString(),
      imageWidth: data['imageWidth'] is num
          ? (data['imageWidth'] as num).toDouble()
          : null,
      imageHeight: data['imageHeight'] is num
          ? (data['imageHeight'] as num).toDouble()
          : null,
      contactData: data['contactData'] is Map
          ? Map<String, dynamic>.from(data['contactData'] as Map)
          : null,
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : null,
      read: data['read'] == true,
      readAt: data['readAt'] is Timestamp ? data['readAt'] as Timestamp : null,
      readBy: data['readBy']?.toString(),
      editedAt: data['editedAt'] is Timestamp
          ? data['editedAt'] as Timestamp
          : null,
      isDeleted: data['isDeleted'] == true,
      starredBy: data['starredBy'] is List
          ? List<String>.from(data['starredBy'].map((e) => e.toString()))
          : <String>[],
      deletedFor: data['deletedFor'] is List
          ? List<String>.from(data['deletedFor'].map((e) => e.toString()))
          : <String>[],
      reactions: data['reactions'] is Map
          ? Map<String, List<String>>.from(
              (data['reactions'] as Map).map(
                (k, v) => MapEntry(
                  k.toString(),
                  v is List
                      ? List<String>.from(v.map((e) => e.toString()))
                      : <String>[],
                ),
              ),
            )
          : null,
      replyToId: data['replyToId']?.toString(),
    );
  }

  factory Message.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Message.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toCreateMap() {
    final data = <String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageType': messageType.value,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
      'readAt': readAt,
      'readBy': readBy,
    };

    if (fileUrl != null) data['fileUrl'] = fileUrl;
    if (fileName != null) data['fileName'] = fileName;
    if (mimeType != null) data['mimeType'] = mimeType;
    if (fileSize != null) data['fileSize'] = fileSize;
    if (thumbnailUrl != null) data['thumbnailUrl'] = thumbnailUrl;
    if (imageWidth != null) data['imageWidth'] = imageWidth;
    if (imageHeight != null) data['imageHeight'] = imageHeight;
    if (contactData != null) data['contactData'] = contactData;
    if (editedAt != null) data['editedAt'] = editedAt;
    if (isDeleted) data['isDeleted'] = isDeleted;
    if (starredBy != null && starredBy!.isNotEmpty) {
      data['starredBy'] = starredBy;
    }
    if (deletedFor != null && deletedFor!.isNotEmpty) {
      data['deletedFor'] = deletedFor;
    }

    return data;
  }

  String get previewText {
    switch (messageType) {
      case MessageType.image:
        return text.trim().isNotEmpty ? text : '[Photo]';
      case MessageType.document:
        return text.trim().isNotEmpty ? text : '[Document]';
      case MessageType.contact:
        return text.trim().isNotEmpty ? text : '[Contact]';
      case MessageType.text:
        return text;
    }
  }

  bool isStarredBy(String userId) {
    return (starredBy ?? <String>[]).contains(userId);
  }
}
