import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/theme_provider.dart';
import '../services/user_service.dart';
import 'call_contacts_screen.dart';
import 'communities_screen.dart';
import 'feed_screen.dart';
import 'messages_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  late final UserService _userService;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    WidgetsBinding.instance.addObserver(this);
    _userService.setUserOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _userService.setUserOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _userService.setUserOnline(false);
    }
  }

  Future<void> _signOut() async {
    await _userService.setUserOnline(false);
    await _auth.signOut();
  }

  Widget _buildBody(BuildContext context) {
    final currentUser = _auth.currentUser;
    return <Widget>[
      FeedContent(
        feedType: 'class',
        auth: widget.auth,
        firestore: widget.firestore,
      ),
      const CallContactsScreen(),
      const CommunitiesScreen(),
      widget.messagesScreenBuilder != null
          ? widget.messagesScreenBuilder!(context)
          : MessagesScreen(
              auth: widget.auth,
              firestore: widget.firestore,
              onBack: () => setState(() => _currentIndex = 0),
              themeProvider: widget.themeProvider ?? ThemeProvider(),
            ),
      ProfileScreen(
        userId: currentUser?.uid ?? '',
        isCurrentUser: true,
        themeProvider: widget.themeProvider,
      ),
    ][_currentIndex];
  }

  Widget _buildChatsIcon() {
    final firestore = widget.firestore ?? FirebaseFirestore.instance;
    final currentUserId = _auth.currentUser?.uid;

    final stream = widget.unreadCountStream ??
        (currentUserId == null
            ? const Stream<int>.empty()
            : firestore
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('read', isEqualTo: false)
                .snapshots()
                .map((snapshot) => snapshot.docs.length));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.mail),
        Positioned(
          right: -6,
          top: -6,
          child: StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count <= 0) return const SizedBox.shrink();
              final cs = Theme.of(context).colorScheme;
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.secondary,
                  shape: BoxShape.circle,
                ),
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

  @override
  Widget build(BuildContext context) {
    final isFeedPage = _currentIndex == 0;

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
            Flexible(child: Text(widget.title)),
          ],
        ),
        actions: [
          if (isFeedPage)
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
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
      ),
    );
  }
}
