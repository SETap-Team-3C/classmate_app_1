import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HashtagService {
  HashtagService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Extracts hashtags from text (e.g., #hashtag, #CS101)
  static Set<String> extractHashtags(String text) {
    final hashtags = <String>{};
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    for (final match in matches) {
      final tag = match.group(1)?.toLowerCase() ?? '';
      if (tag.isNotEmpty) {
        hashtags.add(tag);
      }
    }
    return hashtags;
  }

  /// Records hashtag usage when a post is created
  Future<void> recordHashtags(
    String postId,
    String feedType,
    Set<String> hashtags,
  ) async {
    if (hashtags.isEmpty) return;

    final batch = _firestore.batch();
    for (final tag in hashtags) {
      final hashtagRef = _firestore.collection('hashtags').doc(tag);
      batch.set(hashtagRef, {
        'tag': tag,
        'count': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also store post reference for querying
      batch.set(hashtagRef.collection('posts').doc(postId), {
        'postId': postId,
        'feedType': feedType,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Removes hashtag usage when a post is deleted
  Future<void> removeHashtags(String postId, Set<String> hashtags) async {
    if (hashtags.isEmpty) return;

    final batch = _firestore.batch();
    for (final tag in hashtags) {
      final hashtagRef = _firestore.collection('hashtags').doc(tag);
      batch.update(hashtagRef, {'count': FieldValue.increment(-1)});
      batch.delete(hashtagRef.collection('posts').doc(postId));
    }
    await batch.commit();
  }

  /// Gets trending hashtags
  Stream<List<Map<String, dynamic>>> getTrendingHashtags({int limit = 10}) {
    return _firestore
        .collection('hashtags')
        .orderBy('count', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {
                  'tag': doc['tag'] as String,
                  'count': doc['count'] as int? ?? 0,
                  ...doc.data(),
                },
              )
              .toList();
        });
  }

  /// Gets posts for a specific hashtag
  Stream<QuerySnapshot<Map<String, dynamic>>> getPostsForHashtag(
    String tag,
    String feedType,
  ) {
    return _firestore
        .collection('hashtags')
        .doc(tag.toLowerCase())
        .collection('posts')
        .where('feedType', isEqualTo: feedType)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Searches hashtags by prefix
  Stream<List<Map<String, dynamic>>> searchHashtags(String prefix) {
    if (prefix.isEmpty) return Stream.value([]);

    final searchTag = prefix.toLowerCase();
    final endTag = searchTag.replaceRange(
      searchTag.length - 1,
      searchTag.length,
      String.fromCharCode(searchTag.codeUnitAt(searchTag.length - 1) + 1),
    );

    return _firestore
        .collection('hashtags')
        .where('tag', isGreaterThanOrEqualTo: searchTag)
        .where('tag', isLessThan: endTag)
        .orderBy('tag')
        .orderBy('count', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {
                  'tag': doc['tag'] as String,
                  'count': doc['count'] as int? ?? 0,
                  ...doc.data(),
                },
              )
              .toList();
        });
  }
}
