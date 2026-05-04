import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isCurrentUser;
  final bool isRead;
  final String readStatusText;
  final bool isStarred;
  final VoidCallback? onStarToggle;
  final Future<void> Function()? onDeleteForMe;
  final Future<void> Function()? onDeleteForEveryone;
  final Future<void> Function()? onDelete;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.isCurrentUser,
    required this.isRead,
    required this.readStatusText,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onDelete,
    this.isStarred = false,
    this.onStarToggle,
  });

  Future<void> _confirmAndPerform(
    BuildContext context, {
    required String title,
    required String confirmText,
    required Future<void> Function()? action,
  }) async {
    if (action == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(confirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await action.call();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isCurrentUser ? cs.primaryContainer : cs.surfaceVariant;

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
                  onLongPress: isCurrentUser && onDeleteForEveryone != null
                    ? () => _confirmAndPerform(
                      context,
                      title: 'Delete Message for Everyone',
                      confirmText:
                        'This will remove the message for everyone in the chat. Continue?',
                      action: onDeleteForEveryone,
                      )
                    : (onDeleteForMe != null
                      ? () => _confirmAndPerform(
                        context,
                        title: 'Delete Message',
                        confirmText:
                          'Are you sure you want to delete your message for you?',
                        action: onDeleteForMe,
                        )
                      : null),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 16,
                            color: isCurrentUser ? cs.onPrimaryContainer : cs.onSurface,
                          ),
                        ),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: isRead ? cs.primary : cs.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isRead ? 'Seen' : 'Sent',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isRead ? cs.primary : cs.onSurface.withOpacity(0.7),
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
              // Show options menu (delete for me, delete for everyone, star/unstar)
              if (onDeleteForMe != null || onDeleteForEveryone != null || onStarToggle != null || onDelete != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: PopupMenuButton<String>(
                    tooltip: 'Message options',
                    onSelected: (value) async {
                      if (value == 'delete_me' && onDeleteForMe != null) {
                        await _confirmAndPerform(
                          context,
                          title: 'Delete Message',
                          confirmText: 'Are you sure you want to delete your message?',
                          action: onDeleteForMe,
                        );
                        return;
                      }
                      if (value == 'delete_everyone' && onDeleteForEveryone != null) {
                        await _confirmAndPerform(
                          context,
                          title: 'Delete Message for Everyone',
                          confirmText: 'This will remove the message for everyone in the chat. Continue?',
                          action: onDeleteForEveryone,
                        );
                        return;
                      }
                      if (value == 'star' && onStarToggle != null) {
                        onStarToggle?.call();
                        return;
                      }
                      if (value == 'delete_generic' && onDelete != null) {
                        await _confirmAndPerform(
                          context,
                          title: 'Delete Message',
                          confirmText: 'Are you sure you want to delete your message?',
                          action: onDelete,
                        );
                        return;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final items = <PopupMenuEntry<String>>[];

                      if (onStarToggle != null) {
                        items.add(PopupMenuItem<String>(
                          value: 'star',
                          child: Row(
                            children: [
                              Icon(
                                isStarred ? Icons.star : Icons.star_border,
                                color: isStarred ? cs.secondary : cs.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(isStarred ? 'Unstar' : 'Star'),
                            ],
                          ),
                        ));
                      }

                      if (onDeleteForMe != null) {
                        items.add(PopupMenuItem<String>(
                          value: 'delete_me',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: cs.onSurface),
                              const SizedBox(width: 8),
                              const Text('Delete for me'),
                            ],
                          ),
                        ));
                      }

                      // Single 'Delete' entry for older tests that rely on a single callback.
                      if (onDelete != null) {
                        items.add(const PopupMenuItem<String>(
                          value: 'delete_generic',
                          child: Text('Delete'),
                        ));
                      }

                      if (isCurrentUser && onDeleteForEveryone != null) {
                        items.add(PopupMenuItem<String>(
                          value: 'delete_everyone',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: cs.error),
                              const SizedBox(width: 8),
                              const Text('Delete for everyone'),
                            ],
                          ),
                        ));
                      }

                      return items;
                    },
                    child: Icon(
                      Icons.more_vert,
                      color: cs.onSurface,
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
              style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
      ],
    );
  }
}
