import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation with ${widget.receiverName}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
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

                      return RefreshIndicator(
                        onRefresh: () async {
                          // Trigger refresh by re-fetching messages
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView(
                          children: messages.asMap().entries.map((entry) {
                            final message = entry.value;
                            final messageId = message.id;
                            final isCurrentUser =
                                message.senderId == _auth!.currentUser!.uid;
                            final isRead = message.read;
                            final readAt = message.readAt;

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
                                        ? 'seen ${TimeFormatter.formatTimeAgo(readAt)}'
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
                        ),
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
