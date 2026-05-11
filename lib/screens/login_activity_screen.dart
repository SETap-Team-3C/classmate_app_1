import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../services/login_activity_service.dart';

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  final LoginActivityService _loginActivityService = LoginActivityService();

  String _formatLastSeen(DateTime? time) {
    final loc = AppLocalizations.of(context);
    if (time == null) return loc.t('just_now');

    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return loc.t('just_now');
    if (diff.inMinutes < 60) {
      return loc.t('minutes_ago', params: {'count': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return loc.t('hours_ago', params: {'count': diff.inHours.toString()});
    }
    return loc.t('days_ago', params: {'count': diff.inDays.toString()});
  }

  Future<void> _logoutDevice(LoginActivitySession session) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.t('confirm_logout_device_title')),
        content: Text(loc.t('confirm_logout_device_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.t('log_out_device')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (session.isCurrentDevice) {
      await _loginActivityService.logoutCurrentSession();
      return;
    }

    await _loginActivityService.revokeSession(
      userId: currentUser.uid,
      sessionId: session.sessionId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('device_logged_out'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('login_activity')),
        centerTitle: true,
      ),
      body: user == null
          ? Center(child: Text(loc.t('not_available')))
          : StreamBuilder<List<LoginActivitySession>>(
              stream: _loginActivityService.watchSessions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? const <LoginActivitySession>[];

                if (sessions.isEmpty) {
                  return Center(child: Text(loc.t('no_active_sessions')));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      loc.t('login_activity_description'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...sessions.map((session) {
                      final title = session.isCurrentDevice
                          ? '${session.deviceLabel} · ${loc.t('current_device')}'
                          : session.deviceLabel;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            session.isCurrentDevice
                                ? Icons.smartphone
                                : Icons.devices,
                          ),
                          title: Text(title),
                          subtitle: Text(
                            '${session.platformLabel}\n${loc.t('last_active')}: ${_formatLastSeen(session.lastSeen)}',
                          ),
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed: () => _logoutDevice(session),
                            child: Text(loc.t('log_out_device')),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}