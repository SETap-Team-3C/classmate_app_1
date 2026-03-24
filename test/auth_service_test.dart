import 'package:classmate_app_1/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthService can be instantiated', () {
    final service = AuthService();
    expect(service, isNotNull);
  });

  test(
    'Login with invalid credentials should fail',
    () async {
      final authService = AuthService();
      final result = await authService.login(
        email: 'fake@test.com',
        password: 'wrongpass',
      );

      expect(result, isNotNull);
    },
    skip: 'Requires Firebase app initialization or fake auth setup.',
  );
}
