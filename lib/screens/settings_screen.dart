import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';

import '../core/theme/theme_provider.dart';

import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = const [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Dutch',
    'Chinese',
    'Japanese',
    'Korean',
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    });
  }

  Future<void> _setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Language changed to $language')));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: widget.themeProvider,
        builder: (context, _) {
          final isDarkMode = widget.themeProvider.isDarkMode;
          final cs = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          final muted = cs.onSurface.withValues(alpha: 0.7);
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.person, color: muted),
                      title: Text('Email', style: tt.bodyMedium),
                      subtitle: Text(
                        user?.email ?? 'Not available',
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.edit, color: muted),
                      title: Text('Edit Profile', style: tt.bodyMedium),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('Enable Notifications', style: tt.bodyMedium),
                      subtitle: Text(
                        'Receive message notifications',
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      value: _notificationsEnabled,
                      activeThumbColor: cs.primary,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      title: Text('Sound', style: tt.bodyMedium),
                      subtitle: Text(
                        'Play notification sound',
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.palette, color: muted),
                      title: Text('Theme', style: tt.bodyMedium),
                      subtitle: Text(
                        isDarkMode ? 'Dark' : 'Light',
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () async {
                        final selected = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('Select Theme', style: tt.titleMedium),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    isDarkMode
                                        ? Icons.radio_button_unchecked
                                        : Icons.check_circle,
                                    color: muted,
                                  ),
                                  title: Text('Light', style: tt.bodyMedium),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(false),
                                ),
                                ListTile(
                                  leading: Icon(
                                    isDarkMode
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: muted,
                                  ),
                                  title: Text('Dark', style: tt.bodyMedium),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (selected == null) return;
                        await widget.themeProvider.setDarkMode(selected);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.language, color: muted),
                      title: Text('Language', style: tt.bodyMedium),
                      subtitle: Text(
                        _selectedLanguage,
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              'Select Language',
                              style: tt.titleMedium,
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: _languages
                                    .map(
                                      (language) => ListTile(
                                        leading: Icon(
                                          _selectedLanguage == language
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: muted,
                                        ),
                                        title: Text(
                                          language,
                                          style: tt.bodyMedium,
                                        ),
                                        onTap: () => Navigator.of(
                                          dialogContext,
                                        ).pop(language),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (selected == null) return;
                        _setLanguage(selected);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.lock, color: muted),
                      title: Text('Privacy Policy', style: tt.bodyMedium),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.description, color: muted),
                      title: Text('Terms of Service', style: tt.bodyMedium),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text('Cancel', style: tt.bodyMedium),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text('Logout', style: tt.bodyMedium),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout != true) return;
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(themeProvider: widget.themeProvider),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.onError,
                  ),
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
