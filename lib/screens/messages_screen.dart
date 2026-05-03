import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'new_group_screen.dart';
import 'settings_screen.dart';
import '../core/theme/theme_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.auth,
    this.firestore,
    this.showTestEmptyState = false,
    this.showTestEmptyState = false,
    required this.themeProvider,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final bool showTestEmptyState;
  final ThemeProvider themeProvider;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

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
    if (selectedUser.id == currentUser.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself.')),
      );
      return;
    }

    final chatId = _buildChatId(currentUser.uid, selectedUser.id);
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final currentUsername = (currentUserDoc.data()?['name'] ?? '').toString();

    try {
      await _firestore.collection('chats').doc(chatId).set({
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
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return UserSearchBottomSheet(
          firestore: _firestore,
          currentUserId: currentUser.uid,
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
    final currentUser = widget.showTestEmptyState ? null : _auth.currentUser;
    final cs = Theme.of(context).colorScheme;

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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Direct Messages',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuSelection(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'new_group', child: Text('New group')),
                    const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.showTestEmptyState
                ? const Center(child: Text('No chats yet. Tap + to start one.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .where('participants', arrayContains: currentUser?.uid)
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
                        return const Center(
                          child: Text('No chats yet. Tap + to start one.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chatData =
                              chats[index].data() as Map<String, dynamic>;
                          final chatId = chats[index].id;
                          final participants = List<String>.from(
                            chatData['participants'] ?? [],
                          );
                          final otherUserId = participants.firstWhere(
                            (id) => id != currentUser?.uid,
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

                          return FutureBuilder<int>(
                            future: _firestore
                                .collection('messages')
                                .where('chatId', isEqualTo: chatId)
                                .where(
                                  'receiverId',
                                  isEqualTo: currentUser?.uid,
                                )
                                .where('read', isEqualTo: false)
                                .count()
                                .get()
                                .then((snapshot) => snapshot.count ?? 0),
                            builder: (context, unreadSnapshot) {
                              final unreadCount = unreadSnapshot.data ?? 0;
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
                                    border: Border.all(
                                      color: cs.outline,
                                    ),
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
                                                  : cs.onSurface.withOpacity(0.7),
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
                                                color: cs.onSurface.withOpacity(0.7),
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
  const UserSearchBottomSheet({super.key, 
    this.firestore,
    required this.currentUserId,
    required this.onUserSelected,
    this.usersLoader,
  });

  final FirebaseFirestore? firestore;
  final String currentUserId;
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

    return snapshot.docs.where((doc) => doc.id != widget.currentUserId).map((
      doc,
    ) {
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
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search User',
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
                  hintText: 'Search by name or username',
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
                      return const Center(child: Text('No users available.'));
                    }

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Text('No matching users found.'),
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
