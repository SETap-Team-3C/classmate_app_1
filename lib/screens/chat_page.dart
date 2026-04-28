import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final ChatService? chatService;
  final FirebaseAuth? auth;
  final bool showTestEmptyState;

  const ChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.chatService,
    this.auth,
    this.showTestEmptyState = false,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatService? _chatService;
  final TextEditingController _messageController = TextEditingController();
  FirebaseAuth? _auth;

  @override
  void initState() {
    super.initState();
    if (!widget.showTestEmptyState) {
      _auth = widget.auth ?? FirebaseAuth.instance;
      _chatService = widget.chatService ?? ChatService(auth: _auth);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    if (_chatService == null) return;

    await _chatService!.sendMessage(widget.receiverId, messageText);

    _messageController.clear();
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.grey[400],
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.receiverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.showTestEmptyState
                ? const Center(
                    child: Text('No messages yet. Start the conversation.'),
                  )
                : StreamBuilder<List<Message>>(
                    stream: _chatService!.getMessages(
                      _auth!.currentUser!.uid,
                      widget.receiverId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load chat: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Start the conversation.',
                          ),
                        );
                      }

                      messages.sort((a, b) {
                        final aTimestamp = a.timestamp;
                        final bTimestamp = b.timestamp;
                        final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                        final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                        return aMillis.compareTo(bMillis);
                      });

                      // Mark incoming messages as read
                      for (final msg in messages) {
                        final isCurrentUser =
                            msg.senderId == _auth!.currentUser!.uid;
                        final isRead = msg.read;

                        if (!isCurrentUser && !isRead) {
                          _chatService!.markMessageAsRead(
                            msg.id,
                            _auth!.currentUser!.uid,
                          );
                        }
                      }

                      return ListView(
                        children: messages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final message = entry.value;
                          final messageId = message.id;
                          final isCurrentUser =
                              message.senderId == _auth!.currentUser!.uid;
                          final isRead = message.read;
                          final readAt = message.readAt;
                          final isLastMessage = index == messages.length - 1;

                          return Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (isCurrentUser)
                                MessageBubble(
                                  messageId: messageId,
                                  text: message.text,
                                  isCurrentUser: true,
                                  isRead: isRead,
                                  readStatusText: isRead
                                      ? 'seen ${_formatTimeAgo(readAt)}'
                                      : 'unseen',
                                  onDelete: () =>
                                      _chatService!.deleteMessage(messageId),
                                )
                              else
                                MessageBubble(
                                  messageId: messageId,
                                  text: message.text,
                                  isCurrentUser: false,
                                  isRead: isRead,
                                  readStatusText: '',
                                ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
        ],
      ),
    );
  }
}
