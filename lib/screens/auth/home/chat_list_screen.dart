import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../widets/app_logo.dart';
import '../../../widets/enhanced_avatar.dart';
import '../../settings_screen.dart';
import '../../chat_page.dart';
import '../login_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isSigningOut = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_opened',
      parameters: {'screen': 'chat_list'},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(iconSize: 24),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(themeProvider: widget.themeProvider),
                ),
              );
            },
          ),
          if (_isSigningOut)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  if (!mounted) return;
                  setState(() => _isSigningOut = true);

                  print('Signing out...');

                  // Sign out
                  await FirebaseAuth.instance.signOut();
                  print('Signed out successfully');

                  if (!mounted) return;

                  // Navigate back to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          LoginScreen(themeProvider: widget.themeProvider),
                    ),
                    (route) => false,
                  );
                  print('Navigated to login screen');
                } catch (e) {
                  print('Logout error: $e');
                  if (!mounted) return;
                  setState(() => _isSigningOut = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final users = snapshot.data?.docs ?? const [];
          final query = _query.trim().toLowerCase();

          final filteredUsers = users.where((doc) {
            final user = doc.data();
            final uid = (user['uid'] ?? doc.id).toString();

            if (uid == currentUser?.uid) {
              return false;
            }

            if (query.isEmpty) {
              return true;
            }

            final name = (user['name'] ?? '').toString().toLowerCase();
            final email = (user['email'] ?? '').toString().toLowerCase();
            final username = (user['usernameLower'] ?? user['username'] ?? '')
                .toString()
                .toLowerCase();

            return name.contains(query) ||
                email.contains(query) ||
                username.contains(query);
          }).toList();

          if (users.isEmpty && query.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          if (filteredUsers.isEmpty) {
            return Center(
              child: Text(
                query.isEmpty ? 'No users found' : 'No matching users found',
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, username, or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Trigger refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index].data();
                      final uid = (user['uid'] ?? filteredUsers[index].id)
                          .toString();
                      final name = (user['name'] ?? 'No Name').toString();
                      final email = (user['email'] ?? '').toString();
                      final isOnline = user['isOnline'] as bool? ?? false;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            EnhancedAvatar(name: name, radius: 24),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline ? Colors.green : Colors.grey,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          isOnline ? 'Online' : email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isOnline ? Colors.green : null,
                            fontWeight: isOnline ? FontWeight.w500 : null,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatPage(receiverId: uid, receiverName: name),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
