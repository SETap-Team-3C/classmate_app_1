import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/login_activity_service.dart';
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
  final LoginActivityService _loginActivityService = LoginActivityService();
  StreamSubscription<bool>? _revocationSubscription;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    WidgetsBinding.instance.addObserver(this);
    _userService.setUserOnline(true);
    _ensureSessionRegistered();
    _listenForSessionRevocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _ensureSessionRegistered() async {
    await _loginActivityService.ensureCurrentSession();
  }

  Future<void> _listenForSessionRevocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _revocationSubscription?.cancel();
    _revocationSubscription = _loginActivityService
        .watchCurrentSessionRevoked()
        .listen(
          (isRevoked) async {
            if (!isRevoked || !mounted) return;
            await _userService.setUserOnline(false);
            await _auth.signOut();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Session revocation listener error: $error');
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _userService.setUserOnline(true);
      _loginActivityService.touchCurrentSession();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _userService.setUserOnline(false);
    }
  }

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.t('logout')),
          content: Text(loc.t('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.t('logout')),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await _userService.setUserOnline(false);
    await AuthService().logout();
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

    final stream =
        widget.unreadCountStream ??
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
    final loc = AppLocalizations.of(context);

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
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: loc.t('feed')),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: loc.t('calls'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: loc.t('communities'),
          ),
          BottomNavigationBarItem(
            icon: _buildChatsIcon(),
            label: loc.t('chats'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: loc.t('you'),
          ),
        ],
      ),
    );
  }
}
