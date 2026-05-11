import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classmate_app_1/core/localization/app_localizations.dart';
import 'package:classmate_app_1/services/block_service.dart';

class ProfilePreviewBubble extends StatelessWidget {
  final String userId;
  final Offset position;
  final VoidCallback onProfileTap;
  final Future<void> Function(bool isCurrentlyBlocked) onBlockTap;
  final VoidCallback onClose;

  const ProfilePreviewBubble({
    super.key,
    required this.userId,
    required this.position,
    required this.onProfileTap,
    required this.onBlockTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final left = (position.dx - 150).clamp(12.0, screenSize.width - 312.0);
    final top = (position.dy + 12).clamp(12.0, screenSize.height - 460.0);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).t('user_not_found'),
                      ),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final canBlock =
                    currentUserId != null && currentUserId != userId;
                final name = (userData['name'] ?? 'Unknown').toString();
                final username =
                    (userData['username'] ?? 'user${userId.substring(0, 5)}')
                        .toString();
                final bio = (userData['bio'] ?? '').toString();
                final isOnline = userData['isOnline'] == true;
                final initial = name.isNotEmpty
                    ? name[0].toUpperCase()
                    : username[0].toUpperCase();
                final statusColor = isOnline
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4);
                final statusText = isOnline
                    ? AppLocalizations.of(context).t('online')
                    : AppLocalizations.of(context).t('offline');

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bio.isEmpty
                                    ? AppLocalizations.of(
                                        context,
                                      ).t('not_available')
                                    : bio,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onClose();
                            onProfileTap();
                          },
                          child: Text(
                            AppLocalizations.of(context).t('profile'),
                          ),
                        ),
                      ),
                      if (canBlock) ...[
                        const SizedBox(height: 8),
                        StreamBuilder<bool>(
                          stream: BlockService().isUserBlocked(userId),
                          builder: (context, blockedSnapshot) {
                            final isBlocked = blockedSnapshot.data ?? false;
                            final loc = AppLocalizations.of(context);

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await onBlockTap(isBlocked);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isBlocked
                                      ? Colors.orange
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  isBlocked
                                      ? loc.t('unblock_account')
                                      : loc.t('block_account'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
