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
                svc.showInAppNotification(context, _titleController.text, _bodyController.text);
              },
              child: const Text('Show Now'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                await svc.scheduleNotification(const Duration(seconds: 5), _titleController.text, _bodyController.text);
                if (!mounted) return;
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
