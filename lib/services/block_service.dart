import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class BlockService {
  BlockService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth? get _firebaseAuth =>
      _auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  FirebaseFirestore? get _firebaseFirestore =>
      _firestore ??
      (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  static const String _blockedUserIdsField = 'blockedUserIds';

  DocumentReference<Map<String, dynamic>>? _currentUserDoc() {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final currentUser = auth?.currentUser;
    if (currentUser == null) return null;
    if (firestore == null) return null;

    return firestore.collection('users').doc(currentUser.uid);
  }

  CollectionReference<Map<String, dynamic>>? _blockedCollection() {
    final auth = _firebaseAuth;
    final firestore = _firebaseFirestore;
    final currentUser = auth?.currentUser;
    if (currentUser == null) return null;
    if (firestore == null) return null;

    return firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers');
  }

  Future<void> blockUser(String blockedUserId) async {
    final currentUser = _firebaseAuth?.currentUser;
    if (currentUser == null || blockedUserId.isEmpty) return;
    if (currentUser.uid == blockedUserId) return;

    final userDoc = _currentUserDoc();
    if (userDoc == null) return;

    await userDoc.set({
      _blockedUserIdsField: FieldValue.arrayUnion([blockedUserId]),
    }, SetOptions(merge: true));

    final blockedCollection = _blockedCollection();
    if (blockedCollection == null) return;

    try {
      await blockedCollection.doc(blockedUserId).set({
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Failed to mirror blocked user in subcollection: $error');
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    if (blockedUserId.isEmpty) return;

    final userDoc = _currentUserDoc();
    if (userDoc == null) return;

    await userDoc.set({
      _blockedUserIdsField: FieldValue.arrayRemove([blockedUserId]),
    }, SetOptions(merge: true));

    final blockedCollection = _blockedCollection();
    if (blockedCollection == null) return;

    try {
      await blockedCollection.doc(blockedUserId).delete();
    } catch (error) {
      debugPrint('Failed to remove blocked user mirror doc: $error');
    }
  }

  Stream<Set<String>> watchBlockedUserIds() {
    final userDoc = _currentUserDoc();
    if (userDoc == null) {
      return Stream<Set<String>>.value(<String>{});
    }

    return userDoc.snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final blockedIds = data[_blockedUserIdsField];

      if (blockedIds is Iterable) {
        return blockedIds.map((id) => id.toString()).toSet();
      }

      return <String>{};
    });
  }

  Stream<bool> isUserBlocked(String blockedUserId) {
    if (blockedUserId.isEmpty) {
      return Stream<bool>.value(false);
    }

    final blockedCollection = _blockedCollection();
    if (blockedCollection == null) {
      return Stream<bool>.value(false);
    }

    return blockedCollection
        .doc(blockedUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
