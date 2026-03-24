import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/services/chat_service.dart';

void main() {
  test(
    'ChatService can be instantiated',
    () {
      final service = ChatService();
      expect(service, isNotNull);
    },
    skip: 'Requires Firebase app initialization or fake Firestore instance.',
  );
}
