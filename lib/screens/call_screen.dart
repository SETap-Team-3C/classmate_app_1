import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
<<<<<<< HEAD
import '../core/localization/app_localizations.dart';
=======
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.userName,
    this.userPhone,
    this.launchFn,
  });

  final String userName;
  final String? userPhone;
  final Future<bool> Function(Uri uri)? launchFn;

  static Future<bool> _defaultLaunch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isCalling = false;

  Future<void> _toggleCall() async {
<<<<<<< HEAD
    final loc = AppLocalizations.of(context);
    
=======
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
    if (_isCalling) {
      setState(() {
        _isCalling = false;
      });
      ScaffoldMessenger.of(
        context,
<<<<<<< HEAD
      ).showSnackBar(SnackBar(content: Text(loc.t('call_ended'))));
=======
      ).showSnackBar(const SnackBar(content: Text('Call ended')));
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
      return;
    }

    final phone = widget.userPhone?.trim() ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
        SnackBar(content: Text(loc.t('no_phone_number_found'))),
=======
        const SnackBar(content: Text('No phone number found for this contact')),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await (widget.launchFn ?? CallScreen._defaultLaunch)(uri);

    if (!mounted) return;

    if (launched) {
      setState(() {
        _isCalling = true;
      });
      ScaffoldMessenger.of(
        context,
<<<<<<< HEAD
      ).showSnackBar(SnackBar(content: Text(loc.t('opening_dialer_for', params: {'phone': phone}))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('could_not_open_dialer'))),
=======
      ).showSnackBar(SnackBar(content: Text('Opening dialer for $phone')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer')),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('call_with', params: {'name': widget.userName}))),
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
            if ((widget.userPhone ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.userPhone!,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
<<<<<<< HEAD
                loc.t('opens_phone_dialer_using_saved_contact'),
=======
                'This opens the phone dialer using the saved contact number.',
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),
            FloatingActionButton.extended(
              onPressed: _toggleCall,
              backgroundColor: _isCalling
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondary,
              icon: Icon(_isCalling ? Icons.call_end : Icons.call),
<<<<<<< HEAD
              label: Text(_isCalling ? loc.t('end_call') : loc.t('open_dialer')),
=======
              label: Text(_isCalling ? 'End Call' : 'Open Dialer'),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
            ),
          ],
        ),
      ),
    );
  }
}
