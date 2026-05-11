import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/hashtag_browser_screen.dart';
import 'hashtag_text.dart';

class _CommentNode {
  _CommentNode({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
  final List<_CommentNode> children = [];
}

class CommentsSheetWidget extends StatefulWidget {
  const CommentsSheetWidget({
    super.key,
    required this.postId,
    required this.feedType,
    required this.postAuthorId,
    required this.blockedUserIds,
    this.auth,
    this.firestore,
  });

  final String postId;
  final String feedType;
  final String postAuthorId;
  final Set<String> blockedUserIds;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<CommentsSheetWidget> createState() => _CommentsSheetWidgetState();
}

class _CommentsSheetWidgetState extends State<CommentsSheetWidget> {
  final TextEditingController _commentController = TextEditingController();
  final expandedCommentIds = <String>{};
  String? replyTargetId;
  String? replyTargetName;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  String get _collectionName => 'posts_${widget.feedType}';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int _compareByCreatedAt(
    Map<String, dynamic> left,
    Map<String, dynamic> right, {
    bool descending = false,
  }) {
    final leftDate = _timestampToDate(left['createdAt']);
    final rightDate = _timestampToDate(right['createdAt']);
    return descending
        ? rightDate.compareTo(leftDate)
        : leftDate.compareTo(rightDate);
  }

  DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<_CommentNode> _buildCommentTree(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final nodes = <String, _CommentNode>{};
    for (final doc in docs) {
      nodes[doc.id] = _CommentNode(id: doc.id, data: doc.data());
    }

    final roots = <_CommentNode>[];
    for (final node in nodes.values) {
      final parentId = (node.data['parentCommentId'] ?? '').toString();
      if (parentId.isNotEmpty && nodes.containsKey(parentId)) {
        nodes[parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    void sortNodes(List<_CommentNode> commentNodes) {
      commentNodes.sort(
        (left, right) =>
            _compareByCreatedAt(left.data, right.data, descending: true),
      );
      for (final node in commentNodes) {
        sortNodes(node.children);
      }
    }

    sortNodes(roots);
    return roots;
  }

  Future<void> _postComment(String text, {String? parentCommentId}) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    await _firestore
        .collection(_collectionName)
        .doc(widget.postId)
        .collection('comments')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email ?? 'User',
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'parentCommentId': parentCommentId,
        });
  }

  Future<void> _toggleLikeComment(String commentId, String userId) async {
    try {
      final likeRef = _firestore
          .collection(_collectionName)
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      final doc = await likeRef.get();
      if (doc.exists) {
        await likeRef.delete();
      } else {
        await likeRef.set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reply like: $e')),
      );
    }
  }

  Future<void> _togglePinComment(String commentId, bool isPinned) async {
    await _firestore
        .collection(_collectionName)
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'isPinned': !isPinned,
          'pinnedAt': !isPinned ? FieldValue.serverTimestamp() : null,
        });
  }

  Future<void> _deleteCommentTree(
    String commentId,
    Map<String, List<String>> childrenByParent,
  ) async {
    final idsToDelete = <String>[];

    void collect(String currentId) {
      idsToDelete.add(currentId);
      for (final childId in childrenByParent[currentId] ?? const <String>[]) {
        collect(childId);
      }
    }

    collect(commentId);

    final batch = _firestore.batch();
    final commentsCollection = _firestore
        .collection(_collectionName)
        .doc(widget.postId)
        .collection('comments');
    for (final id in idsToDelete) {
      batch.delete(commentsCollection.doc(id));
    }

    await batch.commit();
  }

  Widget _buildCommentTile({
    required _CommentNode node,
    required int depth,
    required String? currentUserId,
    required Map<String, List<String>> childrenByParent,
    required StateSetter setSheetState,
  }) {
    final data = node.data;
    final authorId = (data['userId'] ?? '').toString();
    final authorName = (data['userName'] ?? 'User').toString();
    final text = (data['text'] ?? '').toString();
    final isOwnedByCurrentUser =
        currentUserId != null && authorId == currentUserId;
    final canPinComment =
        currentUserId != null && widget.postAuthorId == currentUserId;
    final isPinned = data['isPinned'] == true;
    final hasChildren = node.children.isNotEmpty;
    final isRepliesExpanded = expandedCommentIds.contains(node.id);
    final indent = 14.0 * depth;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: depth == 0 ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: Colors.deepPurple.shade200, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (isPinned)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 10, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      replyTargetId = node.id;
                      replyTargetName = authorName;
                    });
                  },
                  child: const Text('Reply'),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection(_collectionName)
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(node.id)
                      .collection('likes')
                      .snapshots(),
                  builder: (context, likeSnapshot) {
                    final likeCount = likeSnapshot.data?.docs.length ?? 0;
                    final isLiked =
                        likeSnapshot.data?.docs.any(
                          (doc) => doc.id == currentUserId,
                        ) ??
                        false;

                    return IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                        size: 18,
                      ),
                      onPressed: currentUserId != null
                          ? () => _toggleLikeComment(node.id, currentUserId)
                          : null,
                      tooltip:
                          '$likeCount ${likeCount == 1 ? "like" : "likes"}',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
                if (isOwnedByCurrentUser || canPinComment)
                  PopupMenuButton<String>(
                    tooltip: 'Comment options',
                    onSelected: (value) async {
                      if (value == 'delete' && isOwnedByCurrentUser) {
                        await _deleteCommentTree(node.id, childrenByParent);
                      } else if (value == 'pin' && canPinComment) {
                        await _togglePinComment(node.id, isPinned);
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      if (canPinComment)
                        PopupMenuItem<String>(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                              ),
                              const SizedBox(width: 8),
                              Text(isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                      if (isOwnedByCurrentUser)
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
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
              ],
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: HashtagText(
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
              ),
            if (hasChildren) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setSheetState(() {
                    if (expandedCommentIds.contains(node.id)) {
                      expandedCommentIds.remove(node.id);
                    } else {
                      expandedCommentIds.add(node.id);
                    }
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isRepliesExpanded
                      ? 'Hide replies'
                      : 'View ${node.children.length} ${node.children.length == 1 ? 'reply' : 'replies'}',
                ),
              ),
            ],
            if (hasChildren && isRepliesExpanded) ...[
              const SizedBox(height: 6),
              ...node.children.map(
                (child) => _buildCommentTile(
                  node: child,
                  depth: depth + 1,
                  currentUserId: currentUserId,
                  childrenByParent: childrenByParent,
                  setSheetState: setSheetState,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setSheetState) {
          final currentUserId = _auth.currentUser?.uid;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (replyTargetName != null)
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            replyTargetId = null;
                            replyTargetName = null;
                          });
                        },
                        child: const Text('Cancel reply'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection(_collectionName)
                      .doc(widget.postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data?.docs ?? [];
                    final visibleComments = comments.where((doc) {
                      final userId = (doc.data()['userId'] ?? '').toString();
                      return !widget.blockedUserIds.contains(userId);
                    }).toList();

                    if (visibleComments.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }

                    final nodes = _buildCommentTree(visibleComments);
                    final childrenByParent = <String, List<String>>{};
                    for (final doc in visibleComments) {
                      final parentId = (doc.data()['parentCommentId'] ?? '')
                          .toString();
                      if (parentId.isNotEmpty) {
                        childrenByParent
                            .putIfAbsent(parentId, () => <String>[])
                            .add(doc.id);
                      }
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: nodes
                          .map(
                            (node) => _buildCommentTile(
                              node: node,
                              depth: 0,
                              currentUserId: currentUserId,
                              childrenByParent: childrenByParent,
                              setSheetState: setSheetState,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (replyTargetName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Replying to $replyTargetName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment or reply...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final text = _commentController.text.trim();
                            final user = _auth.currentUser;
                            if (text.isEmpty || user == null) return;

                            try {
                              await _postComment(
                                text,
                                parentCommentId: replyTargetId,
                              );
                              if (replyTargetId != null) {
                                expandedCommentIds.add(replyTargetId!);
                              }
                              _commentController.clear();
                              setSheetState(() {
                                replyTargetId = null;
                                replyTargetName = null;
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error posting comment: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
