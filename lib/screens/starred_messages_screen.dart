import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({
    super.key,
    this.auth,
    this.firestore,
    this.chatService,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final ChatService? chatService;

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;
  ChatService get _chatService => widget.chatService ?? ChatService(
        firestore: _firestore,
        auth: _auth,
      );

  // Simple in-memory cache for user names to avoid repeated Firestore reads
  final Map<String, String> _userNameCache = {};
  final Set<String> _loadingUserIds = {};

  Future<void> _ensureUserNameCached(String userId) async {
    if (userId.isEmpty) return;
    if (_userNameCache.containsKey(userId) || _loadingUserIds.contains(userId)) return;
    _loadingUserIds.add(userId);
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;
      String name = 'User';
      if (doc.exists) {
        final raw = doc.data();
        if (raw is Map<String, dynamic>) name = (raw['name'] ?? 'User').toString();
      }
      setState(() {
        _userNameCache[userId] = name;
      });
    } catch (_) {
      // ignore errors and keep default
    } finally {
      _loadingUserIds.remove(userId);
    }
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return 'older';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Starred Messages', style: tt.titleLarge),
        centerTitle: true,
        backgroundColor: cs.primary,
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in to see starred messages.'))
          : StreamBuilder<List<Message>>(
              stream: _chatService.getStarredMessages(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Could not load starred messages: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No starred messages yet.'));
                }

                // Show most recent first
                messages.sort((a, b) {
                  final aMillis = a.timestamp?.millisecondsSinceEpoch ?? 0;
                  final bMillis = b.timestamp?.millisecondsSinceEpoch ?? 0;
                  return bMillis.compareTo(aMillis);
                });

                return ListView.separated(
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    // Determine the other participant to open chat
                    final otherUserId = msg.senderId == currentUser.uid
                        ? msg.receiverId
                        : msg.senderId;
                    // Use cached name when available; otherwise start background load
                    final cachedName = _userNameCache[msg.senderId];
                    if (cachedName == null) {
                      // kick off a background load — UI will update via setState when ready
                      _ensureUserNameCached(msg.senderId);
                    }

                    final senderName = cachedName ?? 'User';

                    return ListTile(
                      title: Text(senderName),
                      subtitle: Text(msg.text),
                      trailing: Text(_formatTimeAgo(msg.timestamp)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              receiverId: otherUserId,
                              receiverName: senderName,
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
