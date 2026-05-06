import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'call_screen.dart';

class CallContactsScreen extends StatelessWidget {
  const CallContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentUserId = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Contact to Call')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users available'));
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users to call'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userName = user['name'] ?? 'Unknown User';
              final userEmail = user['email'] ?? '';

                return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: CircleAvatar(
                  child: Text(userName.isNotEmpty ? userName[0] : '?'),
                ),
                title: Text(userName),
                subtitle: Text(userEmail),
                trailing: IconButton(
                  icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Call $userName',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<CallScreen>(
                        builder: (context) => CallScreen(userName: userName),
                      ),
                    );
                  },
                ),
                onTap: () {
                  // also navigate to call when the tile is tapped
                  Navigator.of(context).push(
                    MaterialPageRoute<CallScreen>(
                      builder: (context) => CallScreen(userName: userName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
