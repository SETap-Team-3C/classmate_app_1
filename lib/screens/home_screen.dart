import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'call_contacts_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'starred_messages_screen.dart';
import 'notification_screen.dart';
import 'communities_screen.dart';
import '../core/theme/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.title,
    this.auth,
    this.firestore,
    this.messagesScreenBuilder,
    this.unreadCountStream,
    this.themeProvider,
  });

  final String title;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final WidgetBuilder? messagesScreenBuilder;
  final Stream<int>? unreadCountStream;
  final ThemeProvider? themeProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  // Firestore may be accessed via widget.firestore when provided.

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
              bundle: DefaultAssetBundle.of(context),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(widget.title)),
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
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.update),
            label: 'Updates',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Communities',
          ),
          BottomNavigationBarItem(
            icon: _buildChatsIcon(),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        onTap: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
    );
  }

  int _currentIndex = 3;

  Widget _buildBody(BuildContext context) {
    final currentUser = widget.auth?.currentUser ?? FirebaseAuth.instance.currentUser;
    final pages = <Widget>[
      const NotificationScreen(),
      const CallContactsScreen(),
      const CommunitiesScreen(),
      widget.messagesScreenBuilder != null
          ? widget.messagesScreenBuilder!(context)
          : MessagesScreen(
              auth: widget.auth,
              firestore: widget.firestore,
              themeProvider: widget.themeProvider ?? ThemeProvider(),
            ),
      ProfileScreen(userId: currentUser?.uid ?? '', isCurrentUser: true),
    ];

    return pages[_currentIndex];
  }

  Widget _buildChatsIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.mail),
        Positioned(
          right: -6,
          top: -6,
          child: StreamBuilder<int>(
            stream: widget.unreadCountStream ??
                widget.firestore
                    ?.collection('messages')
                    .where('receiverId', isEqualTo: widget.auth?.currentUser?.uid)
                    .where('read', isEqualTo: false)
                    .snapshots()
                    .map((s) => s.docs.length) ??
                const Stream<int>.empty(),
            builder: (context, snapshot) {
              final cs = Theme.of(context).colorScheme;
              final count = snapshot.data ?? 0;
              if (count <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: TextStyle(fontSize: 10, color: cs.onSecondary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
