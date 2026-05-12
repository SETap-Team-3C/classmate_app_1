import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  UserService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage;

  FirebaseAuth? get _firebaseAuth =>
      _auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  FirebaseFirestore? get _firebaseFirestore =>
      _firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  FirebaseStorage? get _firebaseStorage =>
      _storage ?? (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  /// Update user online status
  Future<void> setUserOnline(bool isOnline) async {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final user = auth?.currentUser;
    if (user == null) return;
    if (firestore == null) return;

    try {
      await firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Get user online status
  Stream<bool> getUserOnlineStatus(String userId) {
    final firestore = _firebaseFirestore;
    if (firestore == null) return const Stream<bool>.empty();

    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] as bool? ?? false);
  }

  /// Get user last seen timestamp
  Stream<DateTime?> getUserLastSeen(String userId) {
    final firestore = _firebaseFirestore;
    if (firestore == null) return const Stream<DateTime?>.empty();

    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      final timestamp = doc.data()?['lastSeen'] as Timestamp?;
      return timestamp?.toDate();
    });
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String name,
    String? bio,
    String? status,
  }) async {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final user = auth?.currentUser;
    if (user == null) return;
    if (firestore == null) return;

    try {
      await firestore.collection('users').doc(user.uid).update({
        'name': name,
        if (bio != null) 'bio': bio,
        if (status != null) 'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final firestore = _firebaseFirestore;
      if (firestore == null) return null;

      final doc = await firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  /// Stream user profile data
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    final firestore = _firebaseFirestore;
    if (firestore == null) return const Stream<Map<String, dynamic>?>.empty();

    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Upload user profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(XFile imageFile) async {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final storage = _firebaseStorage;
    final user = auth?.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      return null;
    }
    if (firestore == null || storage == null) return null;

    try {
      debugPrint('📸 Reading image file: ${imageFile.name}');
      final bytes = await imageFile.readAsBytes();
      debugPrint('✅ Image bytes read: ${bytes.length} bytes');

      final fileName =
          'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('📁 Storage path: $fileName');
      debugPrint('👤 User ID: ${user.uid}');

      final storageRef = storage.ref().child(fileName);

      debugPrint('📤 Uploading bytes to Firebase Storage...');
      try {
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        debugPrint('⏳ Waiting for upload to complete...');
        await uploadTask;
        debugPrint('✅ Upload complete');
      } catch (uploadError) {
        debugPrint('❌ Upload error: $uploadError');
        debugPrint('❌ Upload error type: ${uploadError.runtimeType}');
        rethrow;
      }

      debugPrint('🔗 Getting download URL...');
      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('✅ Download URL: $downloadUrl');

      debugPrint('👤 Updating user photo URL in Firebase Auth...');
      await user.updatePhotoURL(downloadUrl);
      debugPrint('✅ Auth updated');

      debugPrint('📝 Updating Firestore user document...');
      await firestore.collection('users').doc(user.uid).set({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Firestore updated');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Update user display name
  Future<bool> updateUsername(String newUsername) async {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final user = auth?.currentUser;
    if (user == null) return false;
    if (firestore == null) return false;

    try {
      // Update display name in Firebase Auth
      await user.updateDisplayName(newUsername);

      // Update username in Firestore
      await firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
        'name': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }
}
