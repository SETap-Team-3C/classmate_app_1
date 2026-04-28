import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isCurrentUser;
  final bool isRead;
  final String readStatusText;
  final Future<void> Function()? onDelete;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.isCurrentUser,
    required this.isRead,
    required this.readStatusText,
    this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDelete == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete your message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await onDelete!.call();

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser ? Colors.blue[300] : Colors.grey[300];

    return Column(
      crossAxisAlignment: isCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isCurrentUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  isCurrentUser ? 36 : 12,
                  12,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onLongPress: isCurrentUser && onDelete != null
                      ? () => _confirmDelete(context)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: const TextStyle(fontSize: 16)),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: isRead ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isRead ? 'Seen' : 'Sent',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isRead ? Colors.blue : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isCurrentUser && onDelete != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: PopupMenuButton<String>(
                    tooltip: 'Message options',
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isCurrentUser && readStatusText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 2),
            child: Text(
              readStatusText,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
