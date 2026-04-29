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

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 60,
            color: Colors.grey,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Starred Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentUser == null
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

                          return ListTile(
                            title: FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('users').doc(msg.senderId).get(),
                              builder: (context, userSnap) {
                                String senderName = 'User';
                                if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                                  final raw = userSnap.data!.data();
                                  if (raw is Map<String, dynamic>) {
                                    senderName = (raw['name'] ?? 'User').toString();
                                  }
                                }
                                return Text(senderName);
                              },
                            ),
                            subtitle: Text(msg.text),
                            trailing: Text(_formatTimeAgo(msg.timestamp)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    receiverId: otherUserId,
                                    receiverName: '',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
