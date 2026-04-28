import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../../chat_page.dart';
import '../login_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_opened',
      parameters: {'screen': 'chat_list'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classmate'),
        centerTitle: true,
        actions: [
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
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index].data();
              final uid = (user['uid'] ?? users[index].id).toString();

              if (uid == currentUser?.uid) {
                return const SizedBox.shrink();
              }

              final name = (user['name'] ?? 'No Name').toString();
              final email = (user['email'] ?? '').toString();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(email, style: const TextStyle(fontSize: 13)),
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
          );
        },
      ),
    );
  }
}
