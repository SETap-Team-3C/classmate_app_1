import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async' show TimeoutException;

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<User?> _waitForAuthenticatedUser({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;

    try {
      final user = await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(timeout);
      return user;
    } catch (_) {
      return _auth.currentUser;
    }
  }

  // 🔐 SIGNUP
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting signup for email: $email');
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 💾 Store user in Firestore
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      final activeUser = await _waitForAuthenticatedUser();
      if (activeUser == null) {
        throw FirebaseAuthException(
          code: 'auth-not-ready',
          message: 'Signup completed but FirebaseAuth user is still null.',
        );
      }

      debugPrint('Signup successful for uid: $uid');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth signup error: ${e.code} - ${e.message}');
      return e.message ?? e.code;
    } catch (e) {
      debugPrint('Signup error: $e');
      return "Signup failed: $e";
    }
  }

  // 🔑 LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting login with email: $email');

      // Try to sign in with a timeout
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Login request timed out'),
          );

      final activeUser = await _waitForAuthenticatedUser();
      if (activeUser == null) {
        throw FirebaseAuthException(
          code: 'auth-not-ready',
          message: 'Login completed but FirebaseAuth user is still null.',
        );
      }

      debugPrint('Login successful for user: ${userCredential.user?.email}');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('Login timeout: $e');
      return 'Request timed out - Check your internet connection';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      return e.message ?? e.code;
    } catch (e) {
      debugPrint('Login error: $e');
      return "Login failed: $e";
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 👤 CURRENT USER
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
