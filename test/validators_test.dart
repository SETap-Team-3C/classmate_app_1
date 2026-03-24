import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('Name validation', () {
      expect(Validators.validateName(""), "Name is required");
      expect(Validators.validateName("John"), null);
    });

    test('Email validation', () {
      expect(Validators.validateEmail(""), "Email is required");
      expect(Validators.validateEmail("invalid"), "Enter valid email");
      expect(Validators.validateEmail("test@mail.com"), null);
    });

    test('Password validation', () {
      expect(
        Validators.validatePassword("123"),
        "Password must be at least 6 characters",
      );
      expect(Validators.validatePassword("123456"), null);
    });
  });
}
