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
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          receiverName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
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