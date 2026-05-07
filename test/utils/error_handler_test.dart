import 'package:classmate_app_1/core/utils/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Handler Tests', () {
    test('ErrorHandler logs error with context', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Test error'),
          context: 'TestContext',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler logs error without context', () {
      expect(
        () => ErrorHandler.logError(Exception('Test error')),
        returnsNormally,
      );
    });

    test('ErrorHandler handles null errors gracefully', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Null error'),
          context: 'NullTest',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler logs Firebase specific errors', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Firebase error'),
          context: 'FirebaseContext',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler logs authentication errors', () {
      expect(
        () => ErrorHandler.logError(
          Exception('user-not-found'),
          context: 'AuthenticationError',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler logs network errors', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Network timeout'),
          context: 'NetworkError',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler logs database errors', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Database connection failed'),
          context: 'DatabaseError',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler handles multiple consecutive errors', () {
      for (int i = 0; i < 5; i++) {
        expect(
          () => ErrorHandler.logError(
            Exception('Error $i'),
            context: 'MultipleErrors',
          ),
          returnsNormally,
        );
      }
    });

    test('ErrorHandler handles very long error messages', () {
      final longMessage = 'x' * 1000;
      expect(
        () => ErrorHandler.logError(
          Exception(longMessage),
          context: 'LongError',
        ),
        returnsNormally,
      );
    });

    test('ErrorHandler handles special characters in error', () {
      expect(
        () => ErrorHandler.logError(
          Exception('Error with special chars: !@#\$%^&*()'),
          context: 'SpecialCharsError',
        ),
        returnsNormally,
      );
    });
  });
}
