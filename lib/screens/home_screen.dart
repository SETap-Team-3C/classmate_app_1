import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'call_contacts_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'starred_messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.title,
    this.auth,
    this.firestore,
    this.messagesScreenBuilder,
    this.unreadCountStream,
  });

  final String title;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final WidgetBuilder? messagesScreenBuilder;
  final Stream<int>? unreadCountStream;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(userId: userId, isCurrentUser: true),
                  ),
                );
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: const Center(child: Text('Welcome to Classmate App')),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.grey,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail, size: 32, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              widget.messagesScreenBuilder ??
                              (_) => MessagesScreen(
                                auth: _auth,
                                firestore: _firestore,
                              ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: StreamBuilder<int>(
                      stream:
                          widget.unreadCountStream ??
                          _firestore
                              .collection('messages')
                              .where(
                                'receiverId',
                                isEqualTo: _auth.currentUser?.uid,
                              )
                              .where('read', isEqualTo: false)
                              .snapshots()
                              .map((snapshot) => snapshot.docs.length),
                      builder: (context, snapshot) {
                        final hasUnread = (snapshot.data ?? 0) > 0;
                        return hasUnread
                            ? Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.star, size: 32, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StarredMessagesScreen(
                        auth: _auth,
                        firestore: _firestore,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.call, size: 32, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CallContactsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
