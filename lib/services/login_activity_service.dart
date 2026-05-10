import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginActivitySession {
  const LoginActivitySession({
    required this.sessionId,
    required this.deviceLabel,
    required this.platformLabel,
    required this.createdAt,
    required this.lastSeen,
    required this.isRevoked,
    required this.isCurrentDevice,
  });

  final String sessionId;
  final String deviceLabel;
  final String platformLabel;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final bool isRevoked;
  final bool isCurrentDevice;

  bool get isActive => !isRevoked;
}

class LoginActivityService {
  LoginActivityService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _sessionIdKey = 'login_activity_session_id';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String _platformLabel() {
    if (kIsWeb) return 'Web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  String _deviceLabel() {
    if (kIsWeb) return 'Web browser';
    return '${_platformLabel()} device';
  }

  String _generateSessionId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random().nextInt(1 << 32).toRadixString(16);
    return 'session_${now}_$randomPart';
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getCurrentSessionId() async {
    final prefs = await _prefs;
    return prefs.getString(_sessionIdKey);
  }

  Future<String?> ensureCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final prefs = await _prefs;
    var sessionId = prefs.getString(_sessionIdKey);
    sessionId ??= _generateSessionId();
    await prefs.setString(_sessionIdKey, sessionId);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('loginSessions')
        .doc(sessionId)
        .set({
          'sessionId': sessionId,
          'deviceLabel': _deviceLabel(),
          'platformLabel': _platformLabel(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isRevoked': false,
          'revokedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return sessionId;
  }

  Future<void> touchCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await getCurrentSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      await ensureCurrentSession();
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('loginSessions')
        .doc(sessionId)
        .set({
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isRevoked': false,
        }, SetOptions(merge: true));
  }

  Future<void> revokeSession({
    required String userId,
    required String sessionId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('loginSessions')
        .doc(sessionId)
        .set({
          'isRevoked': true,
          'revokedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<List<LoginActivitySession>> watchSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('loginSessions')
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final currentSessionId = await getCurrentSessionId();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
            return LoginActivitySession(
              sessionId: (data['sessionId'] ?? doc.id).toString(),
              deviceLabel: (data['deviceLabel'] ?? 'Unknown device').toString(),
              platformLabel: (data['platformLabel'] ?? 'Unknown').toString(),
              createdAt: createdAt,
              lastSeen: lastSeen,
              isRevoked: data['isRevoked'] == true || data['revokedAt'] != null,
              isCurrentDevice: doc.id == currentSessionId,
            );
          }).toList();
        });
  }

  Stream<bool> watchCurrentSessionRevoked() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield false;
      return;
    }

    final sessionId = await getCurrentSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      yield false;
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(user.uid)
        .collection('loginSessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists) return true;
          return data?['isRevoked'] == true || data?['revokedAt'] != null;
        });
  }

  Future<void> logoutCurrentSession() async {
    final user = _auth.currentUser;
    final sessionId = await getCurrentSessionId();

    if (user != null && sessionId != null && sessionId.isNotEmpty) {
      await revokeSession(userId: user.uid, sessionId: sessionId);
    }

    await _auth.signOut();

    final prefs = await _prefs;
    await prefs.remove(_sessionIdKey);
  }
}