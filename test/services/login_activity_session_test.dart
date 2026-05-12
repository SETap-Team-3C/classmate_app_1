import 'package:classmate_app_1/services/login_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Activity Session Tests', () {
    test('LoginActivitySession reports active sessions correctly', () {
      final session = LoginActivitySession(
        sessionId: 'session_1',
        deviceLabel: 'Windows device',
        platformLabel: 'Windows',
        createdAt: DateTime.utc(2026, 5, 12, 9),
        lastSeen: DateTime.utc(2026, 5, 12, 10),
        isRevoked: false,
        isCurrentDevice: true,
      );

      expect(session.isActive, isTrue);
      expect(session.sessionId, 'session_1');
      expect(session.deviceLabel, 'Windows device');
      expect(session.platformLabel, 'Windows');
      expect(session.isCurrentDevice, isTrue);
    });

    test('LoginActivitySession reports revoked sessions as inactive', () {
      final session = LoginActivitySession(
        sessionId: 'session_2',
        deviceLabel: 'Android device',
        platformLabel: 'Android',
        createdAt: DateTime.utc(2026, 5, 12, 9),
        lastSeen: DateTime.utc(2026, 5, 12, 10),
        isRevoked: true,
        isCurrentDevice: false,
      );

      expect(session.isActive, isFalse);
      expect(session.isCurrentDevice, isFalse);
    });

    test('LoginActivitySession keeps timestamps available for display', () {
      final createdAt = DateTime.utc(2026, 5, 12, 8, 30);
      final lastSeen = DateTime.utc(2026, 5, 12, 10, 15);
      final session = LoginActivitySession(
        sessionId: 'session_3',
        deviceLabel: 'Web browser',
        platformLabel: 'Web',
        createdAt: createdAt,
        lastSeen: lastSeen,
        isRevoked: false,
        isCurrentDevice: false,
      );

      expect(session.createdAt, createdAt);
      expect(session.lastSeen, lastSeen);
    });
  });
}