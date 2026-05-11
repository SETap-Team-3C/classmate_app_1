import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/hashtag_service.dart';
import '../services/block_service.dart';
import '../widgets/hashtag_text.dart';
import 'profile_screen.dart';

class HashtagBrowserScreen extends StatefulWidget {
  const HashtagBrowserScreen({
    super.key,
    required this.hashtag,
    this.feedType = 'class',
  });

  final String hashtag;
  final String feedType;

  @override
  State<HashtagBrowserScreen> createState() => _HashtagBrowserScreenState();
}

class _HashtagBrowserScreenState extends State<HashtagBrowserScreen> {
  late final HashtagService _hashtagService = HashtagService();
  late final BlockService _blockService = BlockService();
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.hashtag}'), centerTitle: true),
      body: StreamBuilder<Set<String>>(
        stream: _blockService.watchBlockedUserIds(),
        builder: (context, blockedSnapshot) {
          final blockedUserIds = blockedSnapshot.data ?? <String>{};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _hashtagService.getPostsForHashtag(
              widget.hashtag,
              widget.feedType,
            ),
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

              final postDocs = snapshot.data?.docs ?? [];

              // Filter out posts from blocked users
              final visiblePosts = postDocs.where((doc) {
                final userId = (doc.data()['userId'] ?? '').toString();
                return !blockedUserIds.contains(userId);
              }).toList();

              if (visiblePosts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tag, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No posts with #${widget.hashtag}',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: visiblePosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final postDoc = visiblePosts[index];
                  final data = postDoc.data();
                  final postAuthorId = (data['userId'] ?? '').toString();
                  final name = (data['userName'] ?? 'User').toString();
                  final text = (data['text'] ?? '').toString();
                  final imageUrl = (data['imageUrl'] ?? '').toString();
                  final createdAt = data['createdAt'] as Timestamp?;

                  String formatTime(Timestamp? ts) {
                    if (ts == null) return 'Just now';
                    final date = ts.toDate();
                    final now = DateTime.now();
                    final diff = now.difference(date);

                    if (diff.inMinutes < 1) return 'Just now';
                    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
                    if (diff.inHours < 24) return '${diff.inHours}h ago';
                    return '${diff.inDays}d ago';
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProfileScreen(
                                              userId: postAuthorId,
                                              isCurrentUser:
                                                  postAuthorId ==
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatTime(createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
                                    builder: (context) => HashtagBrowserScreen(
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
                                height: 200,
                                errorBuilder: (_, __, ___) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Image could not be loaded.'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
