import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'messages_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import '../services/block_service.dart';
import '../services/hashtag_service.dart';
import '../widgets/profile_preview_bubble.dart';
import '../widgets/hashtag_text.dart';
import 'profile_screen.dart';
import 'hashtag_browser_screen.dart';

class _CommentNode {
  _CommentNode({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
  final List<_CommentNode> children = [];
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.auth, this.firestore});

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _activeFeed = 'class';

  Widget _buildFeedToggle({
    required String label,
    required bool isSelected,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFeedToggle(
              label: 'Class',
              isSelected: _activeFeed == 'class',
              labelColor: Colors.deepPurple,
              onTap: () => setState(() => _activeFeed = 'class'),
            ),
            const SizedBox(width: 10),
            _buildFeedToggle(
              label: 'Mates',
              isSelected: _activeFeed == 'mates',
              labelColor: Colors.black,
              onTap: () => setState(() => _activeFeed = 'mates'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagesScreen(
                    auth: widget.auth ?? FirebaseAuth.instance,
                    firestore: widget.firestore ?? FirebaseFirestore.instance,
                    themeProvider: ThemeProvider(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _activeFeed == 'mates'
          ? FeedContent(
              feedType: 'mates',
              auth: widget.auth,
              firestore: widget.firestore,
            )
          : FeedContent(
              feedType: 'class',
              auth: widget.auth,
              firestore: widget.firestore,
            ),
    );
  }
}

class FeedContent extends StatefulWidget {
  const FeedContent({
    super.key,
    required this.feedType,
    this.auth,
    this.firestore,
  });

  final String feedType;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends State<FeedContent> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final BlockService _blockService = BlockService();
  final HashtagService _hashtagService = HashtagService();
  bool _isPosting = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  OverlayEntry? _profilePreviewOverlay;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  FirebaseAuth? _tryGetAuth() {
    try {
      return widget.auth ?? FirebaseAuth.instance;
    } catch (_) {
      return widget.auth;
    }
  }

  FirebaseFirestore? _tryGetFirestore() {
    try {
      return widget.firestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return widget.firestore;
    }
  }

  String get _collectionName => 'posts_${widget.feedType}';

  @override
  void dispose() {
    _postController.dispose();
    _profilePreviewOverlay?.remove();
    super.dispose();
  }

  void _showProfilePreview(String userId, Offset position) {
    _profilePreviewOverlay?.remove();
    _profilePreviewOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _profilePreviewOverlay?.remove();
          _profilePreviewOverlay = null;
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: ProfilePreviewBubble(
            userId: userId,
            position: position,
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: userId,
                    isCurrentUser:
                        userId == FirebaseAuth.instance.currentUser?.uid,
                  ),
                ),
              );
            },
            onBlockTap: (isCurrentlyBlocked) async {
              final currentUserId = _auth.currentUser?.uid;
              if (currentUserId == null || currentUserId == userId) {
                return;
              }
              final loc = AppLocalizations.of(context);

              // Close the preview overlay first so the dialog opens on the main feed.
              _profilePreviewOverlay?.remove();
              _profilePreviewOverlay = null;

              if (!mounted) return;

              final shouldProceed = await showDialog<bool>(
                context: context,
                useRootNavigator: true,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    isCurrentlyBlocked
                        ? loc.t('unblock_account_confirm_title')
                        : loc.t('block_account_confirm_title'),
                  ),
                  content: Text(
                    isCurrentlyBlocked
                        ? loc.t('unblock_account_confirm_body')
                        : loc.t('block_account_confirm_body'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(loc.t('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        isCurrentlyBlocked
                            ? loc.t('unblock_account')
                            : loc.t('block_account'),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldProceed != true) return;

              if (isCurrentlyBlocked) {
                await _blockService.unblockUser(userId);
              } else {
                await _blockService.blockUser(userId);
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCurrentlyBlocked
                        ? loc.t('account_unblocked')
                        : loc.t('account_blocked'),
                  ),
                ),
              );
            },
            onClose: () {
              _profilePreviewOverlay?.remove();
              _profilePreviewOverlay = null;
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_profilePreviewOverlay!);
  }

  DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted = docs.toList();
    sorted.sort((left, right) {
      final leftData = left.data();
      final rightData = right.data();
      final leftPinned = leftData['isPinned'] == true;
      final rightPinned = rightData['isPinned'] == true;
      if (leftPinned != rightPinned) {
        return leftPinned ? -1 : 1;
      }
      return _compareByCreatedAt(leftData, rightData, descending: true);
    });
    return sorted;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterBlockedPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> blockedUserIds,
  ) {
    if (blockedUserIds.isEmpty) return docs;

    return docs.where((doc) {
      final userId = (doc.data()['userId'] ?? '').toString();
      return !blockedUserIds.contains(userId);
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterBlockedComments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> blockedUserIds,
  ) {
    if (blockedUserIds.isEmpty) return docs;

    return docs.where((doc) {
      final userId = (doc.data()['userId'] ?? '').toString();
      return !blockedUserIds.contains(userId);
    }).toList();
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

  Future<void> _deletePost(String postId) async {
    // Fetch post to get hashtags before deletion
    final postDoc = await _firestore
        .collection(_collectionName)
        .doc(postId)
        .get();
    final hashtags = List<String>.from(postDoc.data()?['hashtags'] ?? []);

    // Delete the post
    await _firestore.collection(_collectionName).doc(postId).delete();

    // Clean up hashtag records
    if (hashtags.isNotEmpty) {
      await _hashtagService.removeHashtags(postId, Set.from(hashtags));
    }
  }

  Future<void> _togglePinComment(
    String postId,
    String commentId,
    bool isPinned,
  ) async {
    await _firestore
        .collection(_collectionName)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'isPinned': !isPinned,
          'pinnedAt': !isPinned ? FieldValue.serverTimestamp() : null,
        });
  }

  Future<void> _toggleLikeComment(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      final likeRef = _firestore
          .collection(_collectionName)
          .doc(postId)
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

  Future<void> _postComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) {
      return;
    }

    await _firestore
        .collection(_collectionName)
        .doc(postId)
        .collection('comments')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email ?? 'User',
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'parentCommentId': parentCommentId,
        });
  }

  Future<void> _deleteCommentTree(
    String postId,
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
        .doc(postId)
        .collection('comments');
    for (final id in idsToDelete) {
      batch.delete(commentsCollection.doc(id));
    }

    await batch.commit();
  }

  Widget _buildCommentTile({
    required String postId,
    required _CommentNode node,
    required int depth,
    required String? currentUserId,
    required String? postAuthorId,
    required Set<String> expandedCommentIds,
    required Map<String, List<String>> childrenByParent,
    required void Function(String commentId, String commentUserName) onReply,
    required void Function(String commentId) onToggleReplies,
    required Future<void> Function(String commentId) onDelete,
  }) {
    final data = node.data;
    final authorId = (data['userId'] ?? '').toString();
    final authorName = (data['userName'] ?? 'User').toString();
    final text = (data['text'] ?? '').toString();
    final isOwnedByCurrentUser =
        currentUserId != null && authorId == currentUserId;
    final canPinComment =
        currentUserId != null && postAuthorId == currentUserId;
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
                  onPressed: () => onReply(node.id, authorName),
                  child: const Text('Reply'),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection(_collectionName)
                      .doc(postId)
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
                          ? () => _toggleLikeComment(
                              postId,
                              node.id,
                              currentUserId,
                            )
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
                        await onDelete(node.id);
                      } else if (value == 'pin' && canPinComment) {
                        await _togglePinComment(postId, node.id, isPinned);
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
                          feedType: 'class',
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (hasChildren) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => onToggleReplies(node.id),
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
                  postId: postId,
                  node: child,
                  depth: depth + 1,
                  currentUserId: currentUserId,
                  postAuthorId: postAuthorId,
                  expandedCommentIds: expandedCommentIds,
                  childrenByParent: childrenByParent,
                  onReply: onReply,
                  onToggleReplies: onToggleReplies,
                  onDelete: onDelete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    final text = _postController.text.trim();

    if (user == null) {
      return;
    }

    if (text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or a photo before posting.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await _uploadPostImage(_selectedImage!, user.uid);
      }

      // Extract hashtags from post text
      final hashtags = HashtagService.extractHashtags(text);

      final postRef = await _firestore.collection(_collectionName).add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'User',
        'userPhotoUrl': user.photoURL ?? '',
        'text': text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'isPinned': false,
        'pinnedAt': null,
        'hashtags': hashtags.toList(),
      });

      // Record hashtags for trending/search
      if (hashtags.isNotEmpty) {
        await _hashtagService.recordHashtags(
          postRef.id,
          widget.feedType,
          hashtags,
        );
      }

      setState(() {
        _postController.clear();
        _selectedImage = null;
        _selectedImageBytes = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post created.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<String> _uploadPostImage(XFile image, String userId) async {
    final bytes = await image.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = _storage.ref().child('post_images/$userId/$fileName');
    final metadata = SettableMetadata(
      contentType: image.mimeType ?? 'image/jpeg',
    );
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _formatCreatedAt(dynamic createdAt) {
    if (createdAt is! Timestamp) {
      return 'Just now';
    }

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

  Future<void> _showComments(
    String postId,
    String postAuthorId,
    Set<String> blockedUserIds,
  ) async {
    final commentController = TextEditingController();
    String? replyTargetId;
    String? replyTargetName;
    final expandedCommentIds = <String>{};

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
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
                            .doc(postId)
                            .collection('comments')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final comments = snapshot.data?.docs ?? [];
                          final visibleComments = _filterBlockedComments(
                            comments,
                            blockedUserIds,
                          );

                          if (visibleComments.isEmpty) {
                            return const Center(
                              child: Text('No comments yet.'),
                            );
                          }

                          final nodes = _buildCommentTree(visibleComments);
                          final childrenByParent = <String, List<String>>{};
                          for (final doc in visibleComments) {
                            final parentId =
                                (doc.data()['parentCommentId'] ?? '')
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
                                    postId: postId,
                                    node: node,
                                    depth: 0,
                                    currentUserId: currentUserId,
                                    postAuthorId: postAuthorId,
                                    expandedCommentIds: expandedCommentIds,
                                    childrenByParent: childrenByParent,
                                    onReply: (commentId, commentUserName) {
                                      setSheetState(() {
                                        replyTargetId = commentId;
                                        replyTargetName = commentUserName;
                                      });
                                    },
                                    onToggleReplies: (commentId) {
                                      setSheetState(() {
                                        if (expandedCommentIds.contains(
                                          commentId,
                                        )) {
                                          expandedCommentIds.remove(commentId);
                                        } else {
                                          expandedCommentIds.add(commentId);
                                        }
                                      });
                                    },
                                    onDelete: (commentId) async {
                                      await _deleteCommentTree(
                                        postId,
                                        commentId,
                                        childrenByParent,
                                      );
                                    },
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
                                  controller: commentController,
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
                                  final text = commentController.text.trim();
                                  final user = _auth.currentUser;
                                  if (text.isEmpty || user == null) return;

                                  try {
                                    await _postComment(
                                      postId,
                                      text,
                                      parentCommentId: replyTargetId,
                                    );
                                    if (replyTargetId != null) {
                                      expandedCommentIds.add(replyTargetId!);
                                    }
                                    commentController.clear();
                                    setSheetState(() {
                                      replyTargetId = null;
                                      replyTargetName = null;
                                    });
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error posting comment: $e',
                                        ),
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
          ),
        ),
      );
    } finally {
      commentController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _tryGetAuth();
    final firestore = _tryGetFirestore();
    final loc = AppLocalizations.of(context);

    if (auth == null || firestore == null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _postController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: loc.t('what_is_on_your_mind'),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Expanded(
            child: Center(child: Text('No posts yet. Create the first one.')),
          ),
        ],
      );
    }

    return StreamBuilder<Set<String>>(
      stream: _blockService.watchBlockedUserIds(),
      builder: (context, blockedSnapshot) {
        final blockedUserIds = blockedSnapshot.data ?? <String>{};

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: loc.t('what_is_on_your_mind'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isPosting ? null : _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Photo'),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedImage != null)
                        TextButton(
                          onPressed: _isPosting
                              ? null
                              : () => setState(() {
                                  _selectedImage = null;
                                  _selectedImageBytes = null;
                                }),
                          child: const Text('Remove'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isPosting ? null : _createPost,
                        child: _isPosting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                key: ValueKey(blockedUserIds),
                stream: firestore
                    .collection(_collectionName)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Could not load posts: ${snapshot.error}'),
                      ),
                    );
                  }

                  final docs = _filterBlockedPosts(
                    _sortedPosts(snapshot.data?.docs ?? []),
                    blockedUserIds,
                  );
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No posts yet. Create the first one.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final postDoc = docs[index];
                      final data = postDoc.data();
                      final postId = postDoc.id;
                      final postAuthorId = (data['userId'] ?? '').toString();
                      final currentUserId = _auth.currentUser?.uid;
                      final isCurrentUserPost =
                          currentUserId != null &&
                          postAuthorId == currentUserId;
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
                              Row(
                                children: [
                                  GestureDetector(
                                    onTapDown: (details) {
                                      _showProfilePreview(
                                        postAuthorId,
                                        details.globalPosition,
                                      );
                                    },
                                    child: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.push_pin,
                                                      size: 12,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Pinned',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
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
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          await _deletePost(postId);
                                        }
                                      },
                                      itemBuilder: (context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
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
                              if (text.isNotEmpty)
                                HashtagText(
                                  text,
                                  onHashtagTap: (hashtag) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HashtagBrowserScreen(
                                              hashtag: hashtag,
                                              feedType: widget.feedType,
                                            ),
                                      ),
                                    );
                                  },
                                ),
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
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection(_collectionName)
                                    .doc(postId)
                                    .collection('likes')
                                    .snapshots(),
                                builder: (context, likeSnapshot) {
                                  final likeCount =
                                      likeSnapshot.data?.docs.length ?? 0;
                                  final currentUser = _auth.currentUser;
                                  final isLiked =
                                      likeSnapshot.data?.docs.any(
                                        (doc) => doc.id == currentUser?.uid,
                                      ) ??
                                      false;

                                  return StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >(
                                    stream: _firestore
                                        .collection(_collectionName)
                                        .doc(postId)
                                        .collection('comments')
                                        .snapshots(),
                                    builder: (context, commentSnapshot) {
                                      final rawComments =
                                          commentSnapshot.data?.docs ?? [];
                                      final visibleComments =
                                          _filterBlockedComments(
                                            rawComments,
                                            blockedUserIds,
                                          );
                                      final commentCount =
                                          visibleComments.length;

                                      return Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isLiked
                                                  ? Colors.red
                                                  : null,
                                            ),
                                            onPressed: () =>
                                                _toggleLike(postId, isLiked),
                                          ),
                                          Text(
                                            likeCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.comment_outlined,
                                            ),
                                            onPressed: () => _showComments(
                                              postId,
                                              postAuthorId,
                                              blockedUserIds,
                                            ),
                                          ),
                                          Text(
                                            commentCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
