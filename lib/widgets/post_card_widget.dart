import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/hashtag_browser_screen.dart';
import 'hashtag_text.dart';

class PostCardWidget extends StatefulWidget {
  const PostCardWidget({
    super.key,
    required this.postDoc,
    required this.feedType,
    required this.blockedUserIds,
    required this.onShowComments,
    required this.onDeletePost,
    required this.onShowProfilePreview,
    this.auth,
    this.firestore,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> postDoc;
  final String feedType;
  final Set<String> blockedUserIds;
  final Function(String postId, String postAuthorId, Set<String> blockedUserIds)
  onShowComments;
  final Function(String postId) onDeletePost;
  final Function(String userId, Offset position) onShowProfilePreview;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  String get _collectionName => 'posts_${widget.feedType}';

  String _formatCreatedAt(dynamic createdAt) {
    if (createdAt is! Timestamp) return 'Just now';

    final date = createdAt.toDate();
    final minutes = DateTime.now().difference(date).inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '${minutes}m ago';

    final hours = DateTime.now().difference(date).inHours;
    if (hours < 24) return '${hours}h ago';

    final days = DateTime.now().difference(date).inDays;
    return '${days}d ago';
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (isLiked) {
        await _firestore
            .collection(_collectionName)
            .doc(postId)
            .collection('likes')
            .doc(user.uid)
            .delete();
      } else {
        await _firestore
            .collection(_collectionName)
            .doc(postId)
            .collection('likes')
            .doc(user.uid)
            .set({
              'userId': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating like: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.postDoc.data();
    final postId = widget.postDoc.id;
    final postAuthorId = (data['userId'] ?? '').toString();
    if (widget.blockedUserIds.contains(postAuthorId)) {
      return const SizedBox.shrink();
    }

    final currentUserId = _auth.currentUser?.uid;
    final isCurrentUserPost =
        currentUserId != null && postAuthorId == currentUserId;
    final isPinned = data['isPinned'] == true;
    final name = (data['userName'] ?? 'User').toString();
    final text = (data['text'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final timeLabel = _formatCreatedAt(data['createdAt']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            Row(
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    widget.onShowProfilePreview(
                      postAuthorId,
                      details.globalPosition,
                    );
                  },
                  child: const CircleAvatar(child: Icon(Icons.person)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.push_pin, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pinned',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUserPost)
                  PopupMenuButton<String>(
                    tooltip: 'Post options',
                    onSelected: (value) {
                      if (value == 'delete') {
                        widget.onDeletePost(postId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.more_vert),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Post text with hashtag support
            if (text.isNotEmpty)
              HashtagText(
                text,
                onHashtagTap: (hashtag) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HashtagBrowserScreen(
                        hashtag: hashtag,
                        feedType: widget.feedType,
                      ),
                    ),
                  );
                },
              ),
            // Post image
            if (text.isNotEmpty && imageUrl.isNotEmpty)
              const SizedBox(height: 10),
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Image could not be loaded.'),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Likes and comments
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(_collectionName)
                  .doc(postId)
                  .collection('likes')
                  .snapshots(),
              builder: (context, likeSnapshot) {
                final likeCount = likeSnapshot.data?.docs.length ?? 0;
                final currentUser = _auth.currentUser;
                final isLiked =
                    likeSnapshot.data?.docs.any(
                      (doc) => doc.id == currentUser?.uid,
                    ) ??
                    false;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection(_collectionName)
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, commentSnapshot) {
                    final rawComments = commentSnapshot.data?.docs ?? [];
                    final visibleComments = rawComments.where((doc) {
                      final userId = (doc.data()['userId'] ?? '').toString();
                      return !widget.blockedUserIds.contains(userId);
                    }).toList();
                    final commentCount = visibleComments.length;

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null,
                          ),
                          onPressed: () => _toggleLike(postId, isLiked),
                        ),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () => widget.onShowComments(
                            postId,
                            postAuthorId,
                            widget.blockedUserIds,
                          ),
                        ),
                        Text(
                          commentCount.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
