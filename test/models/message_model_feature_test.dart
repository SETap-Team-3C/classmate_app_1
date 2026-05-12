import 'package:classmate_app_1/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message Model Feature Tests', () {
    test('MessageType values map to the expected serialized strings', () {
      expect(MessageType.text.value, 'text');
      expect(MessageType.image.value, 'image');
      expect(MessageType.document.value, 'document');
      expect(MessageType.contact.value, 'contact');
    });

    test('fromMap parses a text message with default values', () {
      final message = Message.fromMap('m1', {
        'chatId': 'chat_1',
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': 'Hello classmate',
        'messageType': 'text',
      });

      expect(message.id, 'm1');
      expect(message.chatId, 'chat_1');
      expect(message.senderId, 'u1');
      expect(message.receiverId, 'u2');
      expect(message.messageType, MessageType.text);
      expect(message.previewText, 'Hello classmate');
      expect(message.read, isFalse);
      expect(message.isDeleted, isFalse);
      expect(message.starredBy, isEmpty);
      expect(message.deletedFor, isEmpty);
    });

    test('fromMap falls back to photo preview text for image messages', () {
      final message = Message.fromMap('m2', {
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': '',
        'messageType': 'image',
      });

      expect(message.messageType, MessageType.image);
      expect(message.previewText, '[Photo]');
    });

    test('fromMap falls back to document and contact labels when text is empty', () {
      final documentMessage = Message.fromMap('m3', {
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': '   ',
        'messageType': 'document',
      });
      final contactMessage = Message.fromMap('m4', {
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': '',
        'messageType': 'contact',
      });

      expect(documentMessage.previewText, '[Document]');
      expect(contactMessage.previewText, '[Contact]');
    });

    test('fromMap preserves attachment metadata and starred users', () {
      final timestamp = Timestamp.fromDate(DateTime.utc(2026, 5, 12, 10));
      final message = Message.fromMap('m5', {
        'chatId': 'chat_2',
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': 'Attachment message',
        'messageType': 'image',
        'fileUrl': 'https://example.com/image.jpg',
        'fileName': 'image.jpg',
        'mimeType': 'image/jpeg',
        'fileSize': 1024,
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'imageWidth': 1200,
        'imageHeight': 800,
        'timestamp': timestamp,
        'starredBy': ['u1', 'u3'],
        'deletedFor': ['u4'],
        'replyToId': 'reply_1',
      });

      expect(message.fileUrl, 'https://example.com/image.jpg');
      expect(message.fileName, 'image.jpg');
      expect(message.mimeType, 'image/jpeg');
      expect(message.fileSize, 1024);
      expect(message.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(message.imageWidth, 1200);
      expect(message.imageHeight, 800);
      expect(message.timestamp, timestamp);
      expect(message.replyToId, 'reply_1');
      expect(message.isStarredBy('u1'), isTrue);
      expect(message.isStarredBy('u2'), isFalse);
    });

    test('toCreateMap keeps attachment fields and optional flags', () {
      final message = Message(
        chatId: 'chat_3',
        senderId: 'u1',
        receiverId: 'u2',
        messageType: MessageType.document,
        text: 'Syllabus PDF',
        fileUrl: 'https://example.com/syllabus.pdf',
        fileName: 'syllabus.pdf',
        mimeType: 'application/pdf',
        fileSize: 4096,
        thumbnailUrl: 'https://example.com/thumb.png',
        imageWidth: 640,
        imageHeight: 360,
        contactData: {'name': 'Study Group'},
        read: true,
        readBy: 'u2',
        starredBy: ['u1'],
        deletedFor: ['u3'],
        isDeleted: true,
      );

      final map = message.toCreateMap();

      expect(map['chatId'], 'chat_3');
      expect(map['senderId'], 'u1');
      expect(map['receiverId'], 'u2');
      expect(map['messageType'], 'document');
      expect(map['text'], 'Syllabus PDF');
      expect(map['fileUrl'], 'https://example.com/syllabus.pdf');
      expect(map['fileName'], 'syllabus.pdf');
      expect(map['mimeType'], 'application/pdf');
      expect(map['fileSize'], 4096);
      expect(map['thumbnailUrl'], 'https://example.com/thumb.png');
      expect(map['imageWidth'], 640);
      expect(map['imageHeight'], 360);
      expect(map['contactData'], {'name': 'Study Group'});
      expect(map['read'], isTrue);
      expect(map['readBy'], 'u2');
      expect(map['isDeleted'], isTrue);
      expect(map['starredBy'], ['u1']);
      expect(map['deletedFor'], ['u3']);
      expect(map['timestamp'], isA<FieldValue>());
    });
  });
}