import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.userName});

  final String userName;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isCalling = false;

  void _toggleCall() {
    setState(() {
      _isCalling = !_isCalling;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isCalling ? 'Call started' : 'Call ended')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call with ${widget.userName}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            FloatingActionButton.extended(
              onPressed: _toggleCall,
              backgroundColor: _isCalling
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondary,
              icon: Icon(_isCalling ? Icons.call_end : Icons.call),
              label: Text(_isCalling ? 'End Call' : 'Start Call'),
            ),
          ],
        ),
      ),
    );
  }
}
