import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'call_contacts_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'communities_screen.dart';
import '../core/theme/theme_provider.dart';
import '../services/user_service.dart';

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
  late UserService _userService;

  int _currentIndex = 0;
  final String _activeFeed = 'class';

  Future<void> _signOut() async {
    // Set user as offline before signing out
    await _userService.setUserOnline(false);
    await _auth.signOut();
  }

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    
    // Add lifecycle observer to handle app going to background/foreground
    WidgetsBinding.instance.addObserver(this);
    
    // Set user as online when entering home screen
    _userService.setUserOnline(true);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App brought to foreground
      _userService.setUserOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App sent to background or closed
      _userService.setUserOnline(false);
    }
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
            Flexible(child: Text(widget.title)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      userId: userId,
                      isCurrentUser: true,
                      themeProvider: widget.themeProvider,
                    ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Communities'),
          BottomNavigationBarItem(icon: _buildChatsIcon(), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
        onTap: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final currentUser = widget.auth?.currentUser ?? FirebaseAuth.instance.currentUser;
    final pages = <Widget>[
      FeedContent(
        feedType: _activeFeed,
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
            stream:
                widget.unreadCountStream ??
                widget.firestore
                    ?.collection('messages')
                    .where(
                      'receiverId',
                      isEqualTo: widget.auth?.currentUser?.uid,
                    )
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
}
