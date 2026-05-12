import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class BlockService {
  BlockService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth? get _firebaseAuth =>
      _auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  FirebaseFirestore? get _firebaseFirestore =>
      _firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

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

    final blockedCollection = _blockedCollection();
    if (blockedCollection == null) return;

    await blockedCollection.doc(blockedUserId).set({
      'blockedUserId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String blockedUserId) async {
    final blockedCollection = _blockedCollection();
    if (blockedCollection == null || blockedUserId.isEmpty) return;

    await blockedCollection.doc(blockedUserId).delete();
  }

  Stream<Set<String>> watchBlockedUserIds() {
    final blockedCollection = _blockedCollection();
    if (blockedCollection == null) {
      return Stream<Set<String>>.value(<String>{});
    }

    return blockedCollection.snapshots().map((snapshot) {
      final blocked = <String>{};
      for (final doc in snapshot.docs) {
        blocked.add(doc.id);
      }
      return blocked;
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
