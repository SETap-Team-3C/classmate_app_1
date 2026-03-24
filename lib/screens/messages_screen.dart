import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _buildChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$');
    return usernameRegex.hasMatch(username);
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

  Future<void> _showAddUserDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final usernameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start New Chat'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Enter username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text.trim();
                if (username.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a username.')),
                    );
                  }
                  return;
                }

                if (!_isValidUsername(username)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Username can only use letters, numbers, and underscores. Underscores cannot be first or last.',
                        ),
                      ),
                    );
                  }
                  return;
                }

                QuerySnapshot<Map<String, dynamic>> query;
                try {
                  query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('usernameLower', isEqualTo: username.toLowerCase())
                      .limit(1)
                      .get();
                } on FirebaseException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not search usernames: ${error.message ?? error.code}',
                        ),
                      ),
                    );
                  }
                  return;
                }

                if (query.docs.isEmpty) {
                  query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('name', isEqualTo: username)
                      .limit(1)
                      .get();
                }

                if (query.docs.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username not found.')),
                    );
                  }
                  return;
                }

                final selectedUserDoc = query.docs.first;
                final otherUserId = selectedUserDoc.id;
                final otherUserData = selectedUserDoc.data();

                if (otherUserId == currentUser.uid) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot chat with yourself.')),
                    );
                  }
                  return;
                }

                final chatId = _buildChatId(currentUser.uid, otherUserId);
                final currentUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .get();
                final currentUsername =
                    (currentUserDoc.data()?['name'] ?? '').toString();

                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .set({
                    'participants': [currentUser.uid, otherUserId],
                    'usernames': {
                      currentUser.uid: currentUsername,
                      otherUserId: (otherUserData['name'] ?? '').toString(),
                    },
                    'lastMessage': '',
                    'lastTimestamp': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          receiverId: otherUserId,
                          receiverName: (otherUserData['name'] ?? 'User').toString(),
                        ),
                      ),
                    );
                  }
                } on FirebaseException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not create chat: ${error.message ?? error.code}')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 60,
            color: Colors.grey,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Direct Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
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
                    final chatData = chats[index].data() as Map<String, dynamic>;
                    final chatId = chats[index].id;
                    final participants = List<String>.from(chatData['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != currentUser?.uid,
                      orElse: () => '',
                    );

                    if (otherUserId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final usernames = Map<String, dynamic>.from(chatData['usernames'] ?? {});
                    final receiverName = (usernames[otherUserId] ?? 'User').toString();
                    final lastTimestamp = chatData['lastTimestamp'] as Timestamp?;

                    return FutureBuilder<int>(
                      future: FirebaseFirestore.instance
                          .collection('messages')
                          .where('chatId', isEqualTo: chatId)
                          .where('receiverId', isEqualTo: currentUser?.uid)
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
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                        color: unreadCount > 0 ? Colors.red : Colors.grey,
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTimeAgo(lastTimestamp),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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