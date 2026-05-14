import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  Future<List<_GroupMember>> _loadMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return const <_GroupMember>[];

    final results = await Future.wait(
      memberIds.map((memberId) async {
        final snapshot = await _firestore
            .collection('users')
            .doc(memberId)
            .get();
        final data = snapshot.data();
        final name = (data?['name'] ?? 'User').toString();
        return _GroupMember(id: memberId, name: name);
      }),
    );

    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showMembersSheet(List<String> memberIds) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FutureBuilder<List<_GroupMember>>(
            future: _loadMembers(memberIds),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load members: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final members = snapshot.data ?? const <_GroupMember>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Group members'),
                    subtitle: Text('${members.length} total'),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isCurrentUser =
                            _auth.currentUser?.uid == member.id;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(member.name),
                          subtitle: Text(member.id),
                          trailing: isCurrentUser
                              ? const Chip(label: Text('You'))
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(List<String> memberIds) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final senderName =
        (currentUserDoc.data()?['name'] ?? currentUser.displayName ?? 'User')
            .toString();

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'groupId': widget.groupId,
            'senderId': currentUser.uid,
            'senderName': senderName,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('groups').doc(widget.groupId).set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': currentUser.uid,
      }, SetOptions(merge: true));

      _messageController.clear();
      if (_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      } else {
        _isSending = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName),
            const SizedBox(height: 2),
            const Text('Group conversation', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Members',
            onPressed: () {
              final groupData = _cachedGroupData;
              if (groupData == null) return;
              _showMembersSheet(
                List<String>.from(groupData['members'] ?? const []),
              );
            },
            icon: const Icon(Icons.group),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('groups').doc(widget.groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load group: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = snapshot.data?.data();
          _cachedGroupData = groupData;
          if (groupData == null) {
            return const Center(child: Text('Group not found.'));
          }

          final name = (groupData['name'] ?? widget.groupName).toString();
          final memberIds = List<String>.from(groupData['members'] ?? const []);
          final createdBy = (groupData['createdBy'] ?? '').toString();
          final createdAt = groupData['createdAt'] as Timestamp?;

          if (currentUser != null && !memberIds.contains(currentUser.uid)) {
            return const Center(
              child: Text('You are not a member of this group.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'G',
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      createdBy.isEmpty
                          ? '${memberIds.length} members'
                          : '${memberIds.length} members · created by $createdBy',
                    ),
                    trailing: createdAt == null
                        ? null
                        : Text(_formatTimestamp(createdAt)),
                  ),
                ),
              ),
              Expanded(
                child: currentUser == null
                    ? const Center(
                        child: Text('Please sign in to view group messages.'),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestore
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, messageSnapshot) {
                            if (messageSnapshot.hasError) {
                              // Debug output to help diagnose permission issues
                              debugPrint('[GroupChatPage] Failed to load messages: ${messageSnapshot.error}');
                              debugPrint('[GroupChatPage] currentUser.uid=${currentUser.uid}');
                              debugPrint('[GroupChatPage] group members=${memberIds}');

                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Failed to load messages: ${messageSnapshot.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Current UID: ${currentUser.uid}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Group members: ${memberIds.isEmpty ? 'none' : memberIds.join(', ')}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                          if (messageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final messages = messageSnapshot.data?.docs ?? [];

                          if (messages.isEmpty) {
                            return const Center(
                              child: Text('No group messages yet. Say hello.'),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index].data();
                              final senderId = (message['senderId'] ?? '')
                                  .toString();
                              final senderName =
                                  (message['senderName'] ?? 'User').toString();
                              final text = (message['text'] ?? '').toString();
                              final timestamp =
                                  message['timestamp'] as Timestamp?;
                              final isCurrentUser = senderId == currentUser.uid;

                              return Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isCurrentUser)
                                          Text(
                                            senderName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        if (!isCurrentUser)
                                          const SizedBox(height: 4),
                                        Text(
                                          text,
                                          style: TextStyle(
                                            color: isCurrentUser
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimeAgo(timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isCurrentUser
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                      .withValues(alpha: 0.75)
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Message the group',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(memberIds),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSending
                            ? null
                            : () => _sendMessage(memberIds),
                        icon: _isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic>? _cachedGroupData;

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${messageTime.month}/${messageTime.day}/${messageTime.year}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

class _GroupMember {
  const _GroupMember({required this.id, required this.name});

  final String id;
  final String name;
}
