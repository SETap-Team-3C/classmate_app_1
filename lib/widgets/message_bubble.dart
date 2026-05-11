import 'package:flutter/material.dart';

import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final Map<String, dynamic>? contactData;
  final bool isDeleted;
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
    this.messageType = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.contactData,
    this.isDeleted = false,
    required this.isCurrentUser,
    required this.isRead,
    required this.readStatusText,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onDelete,
    this.isStarred = false,
    this.onStarToggle,
  });

  void _showReadReceiptDetails(BuildContext context, String readStatusText) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Message Read'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Read receipt:'),
            const SizedBox(height: 12),
            Text(
              readStatusText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _humanReadableFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final value = size >= 10 || unitIndex == 0 ? size.round().toString() : size.toStringAsFixed(1);
    return '$value ${units[unitIndex]}';
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (messageType == MessageType.image && fileUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
          child: Image.network(
            fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: 220,
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 220,
              height: 180,
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }

    if (messageType == MessageType.document) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName ?? 'Document',
              style: TextStyle(
                fontSize: 14,
                color: isCurrentUser ? cs.onPrimaryContainer : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (messageType == MessageType.contact) {
      final name = contactData?['displayName']?.toString() ?? 'Contact';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, color: cs.onPrimaryContainer, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: isCurrentUser ? cs.onPrimaryContainer : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await action.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isCurrentUser
        ? cs.primaryContainer
        : cs.surfaceContainerHighest;

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
                          action: onDeleteForEveryone,                        )
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
                        if (isDeleted)
                          Text(
                            '[This message was deleted]',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: isCurrentUser
                                  ? cs.onPrimaryContainer
                                  : cs.onSurface,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAttachmentPreview(context),
                              if (messageType == MessageType.image &&
                                  text.trim().isNotEmpty)
                                const SizedBox(height: 6),
                              if (messageType == MessageType.image &&
                                  text.trim().isNotEmpty)
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isCurrentUser
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              if (messageType == MessageType.text)
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isCurrentUser
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              if (messageType == MessageType.document &&
                                  text.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCurrentUser
                                          ? cs.onPrimaryContainer
                                          : cs.onSurface,
                                    ),
                                  ),
                                ),
                              if (messageType == MessageType.contact &&
                                  text.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCurrentUser
                                          ? cs.onPrimaryContainer
                                          : cs.onSurface,
                                    ),
                                  ),
                                ),
                              if (messageType == MessageType.document &&
                                  fileSize != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _humanReadableFileSize(fileSize),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCurrentUser
                                          ? cs.onPrimaryContainer.withValues(
                                              alpha: 0.7,
                                            )
                                          : cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                            ],
                        ),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: isRead
                                ? () => _showReadReceiptDetails(
                                    context,
                                    readStatusText,
                                  )
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRead ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: isRead
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isRead ? 'Seen' : 'Sent',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isRead
                                        ? cs.primary
                                        : cs.onSurface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                    decoration: isRead
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Show options menu (delete for everyone and generic delete)
              if (onDeleteForEveryone != null || onDelete != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: PopupMenuButton<String>(
                    tooltip: 'Message options',
                    onSelected: (value) async {
                      if (value == 'delete_everyone' &&
                          onDeleteForEveryone != null) {
                        await _confirmAndPerform(
                          context,
                          title: 'Delete Message for Everyone',
                          confirmText:
                              'This will remove the message for everyone in the chat. Continue?',
                          action: onDeleteForEveryone,
                        );
                        return;
                      }
                      if (value == 'delete_generic' && onDelete != null) {
                        await _confirmAndPerform(
                          context,
                          title: 'Delete Message',
                          confirmText:
                              'Are you sure you want to delete your message?',
                          action: onDelete,
                        );
                        return;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final items = <PopupMenuEntry<String>>[];

                      // Single 'Delete' entry for older tests that rely on a single callback.
                      if (onDelete != null) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'delete_generic',
                            child: Text('Delete'),
                          ),
                        );
                      }

                      if (isCurrentUser && onDeleteForEveryone != null) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'delete_everyone',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, color: cs.error),
                                const SizedBox(width: 8),
                                const Text('Delete for everyone'),
                              ],
                            ),
                          ),
                        );
                      }

                      return items;
                    },
                    child: Icon(Icons.more_vert, color: cs.onSurface, size: 18),
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
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}
