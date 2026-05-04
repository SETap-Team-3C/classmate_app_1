import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../core/utils/time_formatter.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final ChatService? chatService;
  final FirebaseAuth? auth;
  final bool showTestEmptyState;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.chatService,
    this.auth,
  });

    this.showTestEmptyState = false,
  }) : super(key: key);
   (cleaned up ChatPage by removing test code)

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  ChatService get _chatService => widget.chatService ?? ChatService(auth: _auth);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(widget.receiverId, text);
      _messageController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.showTestEmptyState ? null : _auth.currentUser;

    if (widget.showTestEmptyState) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.receiverName),
              const SizedBox(height: 2),
              const Text(
                'Direct Message',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        body: const Center(child: Text('No messages yet. Start the conversation.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            const SizedBox(height: 2),
            const Text(
              'Direct Message',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: currentUser == null
                ? const Center(child: Text('Please sign in to view messages.'))
                : StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(currentUser.uid, widget.receiverId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final err = snapshot.error;
                        // If Firestore permission denied, show a friendly empty state
                        if (err is FirebaseException && err.code == 'permission-denied') {
                          return const Center(child: Text('No messages yet.'));
                        }

                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }

                      // Sort by timestamp ascending
                      messages.sort((a, b) {
                        final aMillis = a.timestamp?.millisecondsSinceEpoch ?? 0;
                        final bMillis = b.timestamp?.millisecondsSinceEpoch ?? 0;
                        return aMillis.compareTo(bMillis);
                      });

                      // Mark incoming messages as read
                      for (final msg in messages) {
                        final isCurrentUser = msg.senderId == currentUser.uid;
                        if (!isCurrentUser && !msg.read) {
                          _chatService.markMessageAsRead(msg.id, currentUser.uid);
                        }
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message.senderId == currentUser.uid;

                          final readStatusText = isCurrentUser
                              ? (message.read
                                  ? 'seen ${TimeFormatter.formatTimeAgo(message.readAt)}'
                                  : 'sent')
                              : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: MessageBubble(
                              messageId: message.id,
                              text: message.isDeleted ? '[This message was deleted]' : message.text,
                              isCurrentUser: isCurrentUser,
                              isRead: message.read,
                              readStatusText: readStatusText,
                              isStarred: message.isStarredBy(currentUser.uid),
                              onStarToggle: () async {
                                await _chatService.toggleStar(message.id, currentUser.uid);
                              },
                              onDeleteForMe: () async {
                                await _chatService.deleteMessageForMe(message.id, currentUser.uid);
                              },
                              onDeleteForEveryone: isCurrentUser
                                  ? () async {
                                      await _chatService.deleteMessage(message.id);
                                    }
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
