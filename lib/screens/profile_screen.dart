import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classmate_app_1/widets/enhanced_avatar.dart';
import 'package:classmate_app_1/widets/online_indicator.dart';
import 'package:classmate_app_1/core/utils/time_formatter.dart';
import 'package:classmate_app_1/core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  final ThemeProvider? themeProvider;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
    this.themeProvider,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.t('profile'))),
            body: Center(child: Text(loc.t('user_not_found'))),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final name = userData['name'] ?? 'Unknown';
        final email = userData['email'] ?? '';
        final bio = (userData['bio'] ?? '').toString();
        final username =
            userData['username'] ?? 'user${widget.userId.substring(0, 5)}';
        final profilePictureUrl =
            userData['profilePictureUrl'] ??
            FirebaseAuth.instance.currentUser?.photoURL;
        final isOnline = userData['isOnline'] ?? false;
        final lastSeen = userData['lastSeen'] as Timestamp?;

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.t('profile')),
            centerTitle: true,
            actions: widget.isCurrentUser
                ? [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              themeProvider:
                                  widget.themeProvider ?? ThemeProvider(),
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with Status Indicator
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      EnhancedAvatar(
                        name: name,
                        radius: 60,
                        imageUrl: profilePictureUrl,
                      ),
                      OnlineIndicator(isOnline: isOnline, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Username
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline
                              ? loc.t('online')
                              : lastSeen != null
                              ? loc.t(
                                  'last_seen',
                                  params: {
                                    'time': TimeFormatter.formatTimeAgo(
                                      lastSeen,
                                    ),
                                  },
                                )
                              : loc.t('offline'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isOnline
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bio Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.t('bio'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bio.isEmpty ? loc.t('not_available') : bio,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Posts Section
                  Text(
                    loc.t('posts'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('posts_mates')
                        .where('userId', isEqualTo: widget.userId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final posts = snapshot.data?.docs ?? [];

                      if (posts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '$name ${loc.t('no_posts_yet')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final postDoc = posts[index];
                          final postData = postDoc.data();
                          final postText = (postData['text'] ?? '').toString();
                          final postImageUrl = (postData['imageUrl'] ?? '')
                              .toString();
                          final createdAt = postData['createdAt'] as Timestamp?;

                          String formatTime(Timestamp? timestamp) {
                            if (timestamp == null) return 'Just now';
                            final date = timestamp.toDate();
                            final minutes = DateTime.now()
                                .difference(date)
                                .inMinutes;
                            if (minutes < 1) return 'Just now';
                            if (minutes < 60) return '${minutes}m ago';

                            final hours = DateTime.now()
                                .difference(date)
                                .inHours;
                            if (hours < 24) return '${hours}h ago';

                            final days = DateTime.now().difference(date).inDays;
                            return '${days}d ago';
                          }

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTime(createdAt),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (postText.isNotEmpty)
                                    Text(
                                      postText,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  if (postImageUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        postImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 200,
                                                  color: Colors.grey.shade300,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('contact_information'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              username,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  if (!widget.isCurrentUser)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'userId': widget.userId,
                              'userName': name,
                            },
                          );
                        },
                        icon: const Icon(Icons.message),
                        label: Text(loc.t('send_message')),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
