import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';

import '../core/theme/theme_provider.dart';

import 'profile_settings.dart';

import 'edit_profile_screen.dart'; ed2069d (feat(profile): add EditProfile screen and wire from Settings)

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: Theme.of(context).textTheme.titleLarge), centerTitle: true),
      body: AnimatedBuilder(
        animation: widget.themeProvider,
        builder: (context, _) {
          final isDarkMode = widget.themeProvider.isDarkMode;
          final cs = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          final muted = cs.onSurface.withOpacity(0.7);
          return ListView(
            children: [
          // Account Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
<<<<<<< HEAD
                  leading: const Icon(Icons.person),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not available'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileSettings()),
                    );
                  },
=======
                  leading: Icon(Icons.person, color: muted),
                  title: Text('Email', style: tt.bodyMedium),
                  subtitle: Text(
                    user?.email ?? 'Not available',
                    style: tt.bodySmall?.copyWith(color: muted),
                  ),
                  onTap: () {},
>>>>>>> 576a677 (improve settings screen theming and UI consistency)
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: muted),
                  title: Text('Edit Profile', style: tt.bodyMedium),
                  onTap: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(builder: (context) => const ProfileSettings()),

                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
 ed2069d (feat(profile): add EditProfile screen and wire from Settings)
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
                  'Notifications',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Enable Notifications', style: tt.bodyMedium),
                  subtitle: Text('Receive message notifications', style: tt.bodySmall?.copyWith(color: muted)),
                  value: _notificationsEnabled,
                  activeThumbColor: cs.primary,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: Text('Sound', style: tt.bodyMedium),
                  subtitle: Text('Play notification sound', style: tt.bodySmall?.copyWith(color: muted)),
                  value: _soundEnabled,
                  activeThumbColor: cs.primary,
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
                  'Appearance',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.palette, color: muted),
                  title: Text('Theme', style: tt.bodyMedium),
                  subtitle: Text(isDarkMode ? 'Dark' : 'Light', style: tt.bodySmall?.copyWith(color: muted)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Select Theme', style: tt.titleMedium),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<bool>(
                              title: const Text('Light'),
                              value: false,
                              groupValue: isDarkMode,
                              onChanged: (value) async {
                                if (value == null) return;
                                await widget.themeProvider.setDarkMode(value);
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<bool>(
                              title: const Text('Dark'),
                              value: true,
                              groupValue: isDarkMode,
                              onChanged: (value) async {
                                if (value == null) return;
                                await widget.themeProvider.setDarkMode(value);
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
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
                  'Privacy',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.lock, color: muted),
                  title: Text('Privacy Policy', style: tt.bodyMedium),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.description, color: muted),
                  title: Text('Terms of Service', style: tt.bodyMedium),
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
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: tt.bodyMedium),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(themeProvider: widget.themeProvider),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text('Logout', style: tt.bodyMedium),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onError),
              label: Text('Logout', style: tt.bodyMedium),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
  }
}
