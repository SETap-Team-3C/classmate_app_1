import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classmate_app_1/models/message.dart';

void main() {
  group('Message model test', () {
    test('toMap returns expected keys and values', () {
      final timestamp = Timestamp.now();
      final message = Message(
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Hello',
        timestamp: timestamp,
      );

      final map = message.toMap();

      expect(map['senderId'], 'u1');
      expect(map['receiverId'], 'u2');
      expect(map['text'], 'Hello');
      expect(map['timestamp'], timestamp);
    });
  });
}
