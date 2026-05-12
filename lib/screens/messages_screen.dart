import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'new_group_screen.dart';
import 'settings_screen.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import '../services/block_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.auth,
    this.firestore,
    this.showTestEmptyState = false,
    this.initialTargetUserId,
    this.initialTargetUserName,
    this.onBack,
    required this.themeProvider,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final bool showTestEmptyState;
  final String? initialTargetUserId;
  final String? initialTargetUserName;
  final VoidCallback? onBack;
  final ThemeProvider themeProvider;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _didHandleInitialTarget = false;
  StreamSubscription<Set<String>>? _blockedUsersSubscription;
  Set<String> _blockedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (!widget.showTestEmptyState) {
      _blockedUsersSubscription = _blockService.watchBlockedUserIds().listen((
        ids,
      ) {
        if (!mounted) return;
        setState(() {
          _blockedUserIds = ids;
        });
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialTargetChatIfNeeded();
    });
  }

  @override
  void dispose() {
    _blockedUsersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  FirebaseAuth? _tryGetAuth() {
    try {
      return widget.auth ?? FirebaseAuth.instance;
    } catch (_) {
      return widget.auth;
    }
  }

  FirebaseFirestore? _tryGetFirestore() {
    try {
      return widget.firestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return widget.firestore;
    }
  }

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final BlockService _blockService = BlockService();

  String _buildChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return 'older';
  }

  Future<void> _openChatWithUser({
    required User currentUser,
    required SearchUser selectedUser,
  }) async {
    final loc = AppLocalizations.of(context);

    if (selectedUser.id == currentUser.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('you_cannot_chat_with_yourself'))),
      );
      return;
    }

    if (_blockedUserIds.contains(selectedUser.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('blocked_user_chat_not_allowed'))),
      );
      return;
    }

    final chatId = _buildChatId(currentUser.uid, selectedUser.id);
    final firestore = _tryGetFirestore();
    if (firestore == null) return;

    final currentUserDoc = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final currentUsername = (currentUserDoc.data()?['name'] ?? '').toString();

    try {
      await firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, selectedUser.id],
        'usernames': {
          currentUser.uid: currentUsername,
          selectedUser.id: selectedUser.name,
        },
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            receiverId: selectedUser.id,
            receiverName: selectedUser.name,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create chat: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _showAddUserDialog() async {
    final currentUser = _tryGetAuth()?.currentUser;
    if (currentUser == null) return;
    final firestore = _tryGetFirestore();
    if (firestore == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return UserSearchBottomSheet(
          firestore: firestore,
          currentUserId: currentUser.uid,
          blockedUserIds: _blockedUserIds,
          onUserSelected: (selectedUser) async {
            Navigator.pop(context);
            await _openChatWithUser(
              currentUser: currentUser,
              selectedUser: selectedUser,
            );
          },
        );
      },
    );
  }

  Future<void> _openInitialTargetChatIfNeeded() async {
    if (_didHandleInitialTarget) return;
    _didHandleInitialTarget = true;

    final targetUserId = widget.initialTargetUserId;
    if (targetUserId == null || targetUserId.isEmpty) return;

    final currentUser = _tryGetAuth()?.currentUser;
    final firestore = _tryGetFirestore();
    if (currentUser == null || firestore == null) return;

    if (targetUserId == currentUser.uid) return;

    if (_blockedUserIds.contains(targetUserId)) return;

    var targetName = (widget.initialTargetUserName ?? '').trim();
    if (targetName.isEmpty) {
      final targetDoc = await firestore
          .collection('users')
          .doc(targetUserId)
          .get();
      targetName = (targetDoc.data()?['name'] ?? 'User').toString();
    }

    if (!mounted) return;
    await _openChatWithUser(
      currentUser: currentUser,
      selectedUser: SearchUser(
        id: targetUserId,
        name: targetName,
        username: '',
        email: '',
      ),
    );
  }

  void _handleMenuSelection(String value) {
    if (!mounted) return;
    switch (value) {
      case 'new_group':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewGroupScreen(themeProvider: widget.themeProvider),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsScreen(themeProvider: widget.themeProvider),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.showTestEmptyState
        ? null
        : _tryGetAuth()?.currentUser;
    final firestore = widget.showTestEmptyState ? null : _tryGetFirestore();
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.chat),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            color: cs.primary,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                      return;
                    }
                    Navigator.maybePop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      loc.t('direct_messages'),
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (sheetContext) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(
                                  () => _searchQuery = value.toLowerCase(),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: loc.t('search_chats_hint'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.search),
                              ),
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                Navigator.pop(sheetContext);
                              },
                              child: Text(loc.t('clear')),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuSelection(value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'new_group',
                      child: Text(loc.t('new_group')),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(loc.t('settings')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                widget.showTestEmptyState ||
                    currentUser == null ||
                    firestore == null
                ? Center(child: Text(loc.t('no_chats_yet')))
                : StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('chats')
                        .where('participants', arrayContains: currentUser.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load chats: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chats = snapshot.data!.docs.toList();
                      chats.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTimestamp = aData['lastTimestamp'] as Timestamp?;
                        final bTimestamp = bData['lastTimestamp'] as Timestamp?;
                        final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                        final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                        return bMillis.compareTo(aMillis);
                      });

                      if (chats.isEmpty) {
                        return Center(child: Text(loc.t('no_chats_yet')));
                      }

                      final visibleChats = chats.where((chat) {
                        final chatData = chat.data() as Map<String, dynamic>;
                        final participants = List<String>.from(
                          chatData['participants'] ?? [],
                        );
                        final otherUserId = participants.firstWhere(
                          (id) => id != currentUser.uid,
                          orElse: () => '',
                        );
                        return otherUserId.isNotEmpty &&
                            !_blockedUserIds.contains(otherUserId);
                      }).toList();

                      final filteredChats = _searchQuery.isEmpty
                          ? visibleChats
                          : visibleChats.where((chat) {
                              final chatData =
                                  chat.data() as Map<String, dynamic>;
                              final usernames = Map<String, dynamic>.from(
                                chatData['usernames'] ?? {},
                              );
                              final names = usernames.values
                                  .toString()
                                  .toLowerCase();
                              return names.contains(_searchQuery);
                            }).toList();

                      if (filteredChats.isEmpty) {
                        return Center(child: Text(loc.t('no_chats_yet')));
                      }

                      return ListView.builder(
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chatData =
                              filteredChats[index].data()
                                  as Map<String, dynamic>;
                          final chatId = filteredChats[index].id;
                          final participants = List<String>.from(
                            chatData['participants'] ?? [],
                          );
                          final otherUserId = participants.firstWhere(
                            (id) => id != currentUser.uid,
                            orElse: () => '',
                          );

                          if (otherUserId.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final usernames = Map<String, dynamic>.from(
                            chatData['usernames'] ?? {},
                          );
                          final receiverName =
                              (usernames[otherUserId] ?? 'User').toString();
                          final lastTimestamp =
                              chatData['lastTimestamp'] as Timestamp?;

                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: firestore
                                .collection('messages')
                                .where('chatId', isEqualTo: chatId)
                                .where('receiverId', isEqualTo: currentUser.uid)
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            builder: (context, unreadSnapshot) {
                              final unreadCount = unreadSnapshot.data?.docs.length ?? 0;
                              final unreadText = unreadCount == 0
                                  ? ''
                                  : unreadCount > 3
                                  ? '3+ new messages'
                                  : unreadCount == 1
                                  ? '1 new message'
                                  : '$unreadCount new messages';

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        receiverId: otherUserId,
                                        receiverName: receiverName,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 70,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    border: Border.all(color: cs.outline),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          receiverName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            unreadText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: unreadCount > 0
                                                  ? cs.error
                                                  : cs.onSurface.withValues(
                                                      alpha: 0.7,
                                                    ),
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _formatTimeAgo(lastTimestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SearchUser {
  const SearchUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final String id;
  final String name;
  final String username;
  final String email;
}

class UserSearchBottomSheet extends StatefulWidget {
  const UserSearchBottomSheet({
    super.key,
    this.firestore,
    required this.currentUserId,
    required this.blockedUserIds,
    required this.onUserSelected,
    this.usersLoader,
  });

  final FirebaseFirestore? firestore;
  final String currentUserId;
  final Set<String> blockedUserIds;
  final Future<void> Function(SearchUser user) onUserSelected;
  final Future<List<SearchUser>> Function()? usersLoader;

  @override
  State<UserSearchBottomSheet> createState() => _UserSearchBottomSheetState();
}

class _UserSearchBottomSheetState extends State<UserSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<List<SearchUser>> _usersFuture;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<SearchUser>> _loadUsers() async {
    if (widget.usersLoader != null) {
      final loadedUsers = await widget.usersLoader!();
      return loadedUsers
          .where((user) => user.id != widget.currentUserId)
          .where((user) => !widget.blockedUserIds.contains(user.id))
          .toList();
    }

    final firestore = widget.firestore;
    if (firestore == null) {
      return const <SearchUser>[];
    }

    final snapshot = await firestore
        .collection('users')
        .orderBy('name')
        .limit(300)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != widget.currentUserId)
        .where((doc) => !widget.blockedUserIds.contains(doc.id))
        .map((doc) {
          final data = doc.data();
          final name = (data['name'] ?? 'User').toString();
          final username = (data['usernameLower'] ?? '').toString();
          final email = (data['email'] ?? '').toString();

          return SearchUser(
            id: doc.id,
            name: name,
            username: username,
            email: email,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('search_user'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: loc.t('search_by_name_or_username'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<SearchUser>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load users: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final users = snapshot.data ?? const <SearchUser>[];
                    final filteredUsers = users.where((user) {
                      if (_query.isEmpty) return true;
                      return user.name.toLowerCase().contains(_query) ||
                          user.username.toLowerCase().contains(_query);
                    }).toList();

                    if (users.isEmpty) {
                      return Center(child: Text(loc.t('no_users_available')));
                    }

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(loc.t('no_matching_users_found')),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final subtitle = [
                          if (user.username.isNotEmpty) '@${user.username}',
                          if (user.email.isNotEmpty) user.email,
                        ].join(' • ');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: subtitle.isEmpty
                              ? null
                              : Text(subtitle, overflow: TextOverflow.ellipsis),
                          onTap: () async {
                            await widget.onUserSelected(user);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
