import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';

class UserService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  /// Update user online status
  Future<void> setUserOnline(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Get user online status
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] as bool? ?? false);
  }

  /// Get user last seen timestamp
  Stream<DateTime?> getUserLastSeen(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
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
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        if (bio != null) 'bio': bio,
        if (status != null) 'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  /// Stream user profile data
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Upload user profile picture
  Future<String?> uploadProfilePicture(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return null;
    }

    try {
      print('📸 Reading image file: ${imageFile.name}');
      final bytes = await imageFile.readAsBytes();
      print('✅ Image bytes read: ${bytes.length} bytes');

      final fileName =
          'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('📁 Storage path: $fileName');
      print('👤 User ID: ${user.uid}');
      
      final storageRef = _storage.ref().child(fileName);

      print('📤 Uploading bytes to Firebase Storage...');
      try {
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        print('⏳ Waiting for upload to complete...');
        await uploadTask;
        print('✅ Upload complete');
      } catch (uploadError) {
        print('❌ Upload error: $uploadError');
        print('❌ Upload error type: ${uploadError.runtimeType}');
        rethrow;
      }
      
      print('🔗 Getting download URL...');
      final downloadUrl = await storageRef.getDownloadURL();
      print('✅ Download URL: $downloadUrl');

      print('👤 Updating user photo URL in Firebase Auth...');
      await user.updatePhotoURL(downloadUrl);
      print('✅ Auth updated');

      print('📝 Updating Firestore user document...');
      await _firestore.collection('users').doc(user.uid).update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore updated');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
        'name': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating username: $e');
      return false;
    }
  }
}
