import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classmate_app_1/models/message.dart';

void main() {
  group('Message model test', () {
    test('toCreateMap returns expected keys and values', () {
      final message = Message(
        chatId: 'chat_1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Hello',
      );

      final map = message.toCreateMap();

      expect(map['chatId'], 'chat_1');
      expect(map['senderId'], 'u1');
      expect(map['receiverId'], 'u2');
      expect(map['text'], 'Hello');
      expect(map['timestamp'], isA<FieldValue>());
      expect(map['read'], false);
      expect(map['readAt'], null);
      expect(map['readBy'], null);
    });
  });
}
