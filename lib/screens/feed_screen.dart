import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'messages_screen.dart';
import 'profile_screen.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import '../services/block_service.dart';
import '../services/hashtag_service.dart';
import '../widgets/profile_preview_bubble.dart';
import '../widgets/trending_hashtags_widget.dart';
import '../widgets/post_creation_widget.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/comments_sheet_widget.dart';

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
  final BlockService _blockService = BlockService();
  final HashtagService _hashtagService = HashtagService();
  OverlayEntry? _profilePreviewOverlay;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  String get _collectionName => 'posts_${widget.feedType}';

  @override
  void dispose() {
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
              if (currentUserId == null || currentUserId == userId) return;

              final loc = AppLocalizations.of(context);
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

  Future<void> _deletePost(String postId) async {
    final postDoc = await _firestore
        .collection(_collectionName)
        .doc(postId)
        .get();
    final hashtags = List<String>.from(postDoc.data()?['hashtags'] ?? []);

    await _firestore.collection(_collectionName).doc(postId).delete();

    if (hashtags.isNotEmpty) {
      await _hashtagService.removeHashtags(postId, Set.from(hashtags));
    }
  }

  void _showComments(
    String postId,
    String postAuthorId,
    Set<String> blockedUserIds,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentsSheetWidget(
          postId: postId,
          feedType: widget.feedType,
          postAuthorId: postAuthorId,
          blockedUserIds: blockedUserIds,
          auth: _auth,
          firestore: _firestore,
        ),
      ),
    );
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

      if (leftPinned != rightPinned) return leftPinned ? -1 : 1;

      final leftDate = _getTimestampDate(leftData['createdAt']);
      final rightDate = _getTimestampDate(rightData['createdAt']);
      return rightDate.compareTo(leftDate);
    });
    return sorted;
  }

  DateTime _getTimestampDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
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

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    final firestore = _firestore;

    return StreamBuilder<Set<String>>(
      stream: _blockService.watchBlockedUserIds(),
      builder: (context, blockedSnapshot) {
        final blockedUserIds = blockedSnapshot.data ?? <String>{};

        return Column(
          children: [
            PostCreationWidget(
              feedType: widget.feedType,
              auth: auth,
              firestore: firestore,
              storage: FirebaseStorage.instance,
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
                        child: Text('Error loading posts: ${snapshot.error}'),
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

                  return Column(
                    children: [
                      TrendingHashtagsWidget(
                        feedType: widget.feedType,
                        limit: 5,
                        compact: true,
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return PostCardWidget(
                              postDoc: docs[index],
                              feedType: widget.feedType,
                              blockedUserIds: blockedUserIds,
                              onShowComments: _showComments,
                              onDeletePost: _deletePost,
                              onShowProfilePreview: _showProfilePreview,
                              auth: auth,
                              firestore: firestore,
                            );
                          },
                        ),
                      ),
                    ],
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
