import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/theme/theme_provider.dart';
import '../core/localization/app_localizations.dart';
import '../services/auth_service.dart';
import 'profile_settings.dart';
import 'login_activity_screen.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = widget.themeProvider.isDarkMode;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('settings')), centerTitle: true),
      body: ListView(
        children: [
          // Account Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('settings_account'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(loc.t('email')),
                  subtitle: Text(user?.email ?? loc.t('not_available')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSettings(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(loc.t('edit_profile')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSettings(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(loc.t('login_activity')),
                  subtitle: Text(loc.t('login_activity_description')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginActivityScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Notifications Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('notifications'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(loc.t('enable_notifications')),
                  subtitle: Text(loc.t('receive_message_notifications')),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: Text(loc.t('sound')),
                  subtitle: Text(loc.t('play_notification_sound')),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Theme Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('appearance'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(loc.t('theme')),
                  subtitle: Text(isDarkMode ? loc.t('dark') : loc.t('light')),
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(loc.t('select_theme')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                isDarkMode
                                    ? Icons.radio_button_unchecked
                                    : Icons.check_circle,
                              ),
                              title: Text(loc.t('light')),
                              onTap: () =>
                                  Navigator.of(dialogContext).pop('light'),
                            ),
                            ListTile(
                              leading: Icon(
                                isDarkMode
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(loc.t('dark')),
                              onTap: () =>
                                  Navigator.of(dialogContext).pop('dark'),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (selected == null) return;
                    await widget.themeProvider.setDarkMode(selected == 'dark');
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Privacy Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('privacy'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text(loc.t('privacy_policy')),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(loc.t('terms_of_service')),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const Divider(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(loc.t('logout')),
                    content: Text(loc.t('logout_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(loc.t('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(loc.t('logout')),
                      ),
                    ],
                  ),
                );

                if (shouldLogout != true) return;
                await AuthService().logout();
                if (!mounted) return;
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(loc.t('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
