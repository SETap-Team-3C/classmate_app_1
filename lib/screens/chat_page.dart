import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class MessageWithDeleteOption extends StatefulWidget {
  final String messageId;
  final String text;
  final ChatService chatService;

  const MessageWithDeleteOption({
    Key? key,
    required this.messageId,
    required this.text,
    required this.chatService,
  }) : super(key: key);

  @override
  State<MessageWithDeleteOption> createState() => _MessageWithDeleteOptionState();
}

class _MessageWithDeleteOptionState extends State<MessageWithDeleteOption> {
  bool _showMenu = false;

  Future<void> _deleteMessage() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete your message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await widget.chatService.deleteMessage(widget.messageId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete message: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showMenu = true),
      onExit: (_) => setState(() => _showMenu = false),
      child: Align(
        alignment: Alignment.centerRight,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_showMenu)
              Positioned(
                right: 0,
                top: 0,
                child: PopupMenuButton<String>(
                  initialValue: null,
                  onSelected: (String value) async {
                    if (value == 'delete') {
                      await _deleteMessage();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: _deleteMessage,
                  child: const SizedBox(width: 1, height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    _chatService.sendMessage(
      widget.receiverId,
      _messageController.text,
    );

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
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(
                _auth.currentUser!.uid,
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation.'),
                  );
                }

                final messages = snapshot.data!.docs.toList();
                messages.sort((a, b) {
                  final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                  final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                  return aMillis.compareTo(bMillis);
                });

                // Mark incoming messages as read
                for (final msg in messages) {
                  final data = msg.data() as Map<String, dynamic>;
                  final isCurrentUser = data['senderId'] == _auth.currentUser!.uid;
                  final isRead = data['read'] ?? false;

                  if (!isCurrentUser && !isRead) {
                    _chatService.markMessageAsRead(msg.id, _auth.currentUser!.uid);
                  }
                }

                return ListView(
                  children: messages.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final messageId = doc.id;
                      final data = doc.data() as Map<String, dynamic>;
                      final isCurrentUser =
                          data['senderId'] == _auth.currentUser!.uid;
                      final isRead = data['read'] ?? false;
                      final readAt = data['readAt'] as Timestamp?;
                      final isLastMessage = index == messages.length - 1;

                      return Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (isCurrentUser)
                            MessageWithDeleteOption(
                              messageId: messageId,
                              text: data['text'],
                              chatService: _chatService,
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['text'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          if (isCurrentUser && isLastMessage)
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 2),
                              child: Text(
                                isRead
                                    ? 'seen ${_formatTimeAgo(readAt)}'
                                    : 'unseen',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ).toList(),
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
