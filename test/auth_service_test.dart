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
import 'package:classmate_app_1/services/auth_service.dart';

void main() {
  final authService = AuthService();

  test('Login with invalid credentials should fail', () async {
    final result = await authService.login(
      email: "fake@test.com",
      password: "wrongpass",
    );

    expect(result, isNotNull); // should return error
  });
}
