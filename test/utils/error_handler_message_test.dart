import 'package:classmate_app_1/core/utils/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Handler Message Tests', () {
    test('maps common auth exception codes to user-friendly messages', () {
      expect(
        ErrorHandler.getErrorMessage(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        'No user found with this email address.',
      );

      expect(
        ErrorHandler.getErrorMessage(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'Incorrect password. Please try again.',
      );

      expect(
        ErrorHandler.getErrorMessage(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'An account with this email already exists.',
      );
    });

    test('maps common Firestore exception codes to user-friendly messages', () {
      expect(
        ErrorHandler.getErrorMessage(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        'You don\'t have permission to perform this action.',
      );

      expect(
        ErrorHandler.getErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        ),
        'The requested document was not found.',
      );

      expect(
        ErrorHandler.getErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        'The service is currently unavailable. Please try again later.',
      );
    });

    test('falls back to a generic message for unknown objects', () {
      expect(
        ErrorHandler.getErrorMessage(Object()),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('Exception extension delegates to the error handler', () {
      const message = 'Something failed';
      expect(Exception(message).toUserMessage(), contains(message));
    });
  });
}