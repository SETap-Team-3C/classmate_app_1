import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classmate_app_1/core/localization/app_localizations.dart';

class ProfilePreviewBubble extends StatelessWidget {
  final String userId;
  final Offset position;
  final VoidCallback onProfileTap;
  final VoidCallback onClose;

  const ProfilePreviewBubble({
    super.key,
    required this.userId,
    required this.position,
    required this.onProfileTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
                final username =
                    userData['username'] ?? 'user${userId.substring(0, 5)}';
                final bio = (userData['bio'] ?? '').toString();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@$username',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (bio.isNotEmpty)
                        Text(
                          bio,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (bio.isEmpty)
                        Text(
                          AppLocalizations.of(context).t('not_available'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
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
