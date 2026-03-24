import 'package:flutter/material.dart';

import '../../chat_page.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classmate')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('General Chat'),
            subtitle: const Text('Tap to open conversation'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatPage(
                    receiverId: 'general',
                    receiverName: 'General Chat',
                    showTestEmptyState: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
