import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class ErrorHandler {
  /// Converts Firebase exceptions to user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    } else if (error is firestore.FirebaseException) {
      return _getFirestoreErrorMessage(error.code);
    } else if (error is Exception) {
      return error.toString();
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle authentication errors
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }

  /// Handle Firestore errors
  static String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'This document already exists.';
      case 'failed-precondition':
        return 'The operation failed due to invalid state.';
      case 'aborted':
        return 'The operation was aborted. Please try again.';
      case 'out-of-range':
        return 'The value is out of range.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      case 'data-loss':
        return 'Data loss occurred. Please contact support.';
      case 'unauthenticated':
        return 'Please sign in to perform this action.';
      case 'invalid-argument':
        return 'Invalid argument provided.';
      case 'resource-exhausted':
        return 'Resource limit exceeded. Please try again later.';
      case 'cancelled':
        return 'The operation was cancelled.';
      case 'internal':
        return 'An internal error occurred. Please try again.';
      case 'deadline-exceeded':
        return 'The operation took too long. Please try again.';
      case 'unknown':
        return 'An unknown error occurred. Please try again.';
      default:
        return 'A Firestore error occurred. Please try again.';
    }
  }

  /// Log error for debugging
  static void logError(dynamic error, {String? context}) {
    final timestamp = DateTime.now().toString();
    final errorMessage = getErrorMessage(error);
    final contextMessage = context != null ? ' (Context: $context)' : '';
    print('[$timestamp] Error: $errorMessage$contextMessage');
    print('Stack trace: $error');
  }

  /// Show error in a user-friendly format
  static void showErrorMessage(String message) {
    // Implementation depends on your UI framework
    // This is a placeholder for error display logic
    print('Error Message: $message');
  }
}

/// Extension to make error handling easier
extension ErrorHandling on Exception {
  String toUserMessage() => ErrorHandler.getErrorMessage(this);

  void log({String? context}) => ErrorHandler.logError(this, context: context);
}
