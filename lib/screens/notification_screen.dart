// created notification screen
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Hello');
  final TextEditingController _bodyController = TextEditingController(text: 'This is a test notification');
  final List<String> _messages = [
    'Welcome to Classmate!',
    'Your assignment is due tomorrow',
    'New message from Raj',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = NotificationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Recent Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Notification list
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(msg),
                      subtitle: const Text('Just now'),
                      onTap: () {
                        // preview or open details later
                        svc.showInAppNotification(context, 'Notification', msg);
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                // show and also add to list for visual feedback
                svc.showInAppNotification(context, _titleController.text, _bodyController.text);
                setState(() {
                  _messages.insert(0, '${_titleController.text}: ${_bodyController.text}');
                });
              },
              child: const Text('Show Now'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                await svc.scheduleNotification(const Duration(seconds: 5), _titleController.text, _bodyController.text);
                if (!mounted) return;
                setState(() {
                  _messages.insert(0, 'Scheduled: ${_titleController.text}: ${_bodyController.text}');
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduled in 5 seconds')));
              },
              child: const Text('Schedule (5s)'),
            ),
          ],
        ),
      ),
    );
  }
}
