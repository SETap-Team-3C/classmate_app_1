import 'package:flutter/material.dart';

/// A tiny notification service used by the app while you decide on
/// a platform notification plugin. This keeps calls to show a notification
/// centralized and testable.
class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  /// Placeholder initialization hook (request permissions, init plugins, etc.)
  Future<void> init() async {
    // TODO: initialize platform notification plugins here
    await Future<void>.value();
  }

  /// Shows an in-app notification using a SnackBar. This is a simple
  /// fallback for UI-level notifications while platform notifications
  /// are not yet wired in.
  void showInAppNotification(BuildContext context, String title, String body) {
    final snack = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  /// A simple scheduling stub for local testing. In a real app this would
  /// schedule a platform notification using a plugin such as
  /// `flutter_local_notifications` or Firebase Cloud Messaging.
  Future<void> scheduleNotification(Duration after, String title, String body) async {
    // TODO: replace with real scheduling via plugin
    await Future<void>.delayed(after);
    // For now, just print to console (or integrate with app-level event handling)
    debugPrint('Scheduled notification: $title - $body');
  }
}
