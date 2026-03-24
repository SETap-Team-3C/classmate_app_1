import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  // 🔐 SIGNUP
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final auth = _auth;
      final db = _db;
      if (auth == null || db == null) {
        return 'Firebase is not configured for this build.';
      }

      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 💾 Store user in Firestore
      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Signup failed";
    }
  }

  // 🔑 LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final auth = _auth;
      if (auth == null) {
        return 'Firebase is not configured for this build.';
      }

      await auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed";
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
  }

  // 👤 CURRENT USER
  User? getCurrentUser() {
    final auth = _auth;
    if (auth == null) return null;
    return auth.currentUser;
  }
}
