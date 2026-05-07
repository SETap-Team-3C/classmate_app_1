import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/language_provider.dart';
import '../core/localization/app_localizations.dart';
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
  final List<String> _languages = const ['English', 'Spanish'];
  bool _loadedLanguage = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedLanguage) return;
    _loadedLanguage = true;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }
  Future<void> _loadLanguagePreference() async {
    _selectedLanguage = LanguageInherited.of(context).codeToLanguageName();
    if (mounted) setState(() {});
  }

  Future<void> _setLanguage(String language) async {
    // Persist language and update runtime locale
    final languageProvider = LanguageInherited.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    await languageProvider.setLocaleByLanguageName(language);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $language')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('settings'), style: Theme.of(context).textTheme.titleLarge),
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
                      AppLocalizations.of(context).t('settings_account'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.person, color: muted),
                      title: Text(AppLocalizations.of(context).t('email'), style: tt.bodyMedium),
                      subtitle: Text(
                        user?.email ?? AppLocalizations.of(context).t('not_available'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.edit, color: muted),
                      title: Text(AppLocalizations.of(context).t('edit_profile'), style: tt.bodyMedium),
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
                      AppLocalizations.of(context).t('notifications'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context).t('enable_notifications'), style: tt.bodyMedium),
                      subtitle: Text(
                        AppLocalizations.of(context).t('receive_message_notifications'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      value: _notificationsEnabled,
                      activeThumbColor: cs.primary,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context).t('sound'), style: tt.bodyMedium),
                      subtitle: Text(
                        AppLocalizations.of(context).t('play_notification_sound'),
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
                      AppLocalizations.of(context).t('appearance'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.palette, color: muted),
                      title: Text(AppLocalizations.of(context).t('theme'), style: tt.bodyMedium),
                      subtitle: Text(
                        isDarkMode
                            ? AppLocalizations.of(context).t('dark')
                            : AppLocalizations.of(context).t('light'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () async {
                        final selected = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(AppLocalizations.of(context).t('select_theme'), style: tt.titleMedium),
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
                                  title: Text(AppLocalizations.of(context).t('light'), style: tt.bodyMedium),
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
                                  title: Text(AppLocalizations.of(context).t('dark'), style: tt.bodyMedium),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: Text(AppLocalizations.of(context).t('cancel')),
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
                      title: Text(AppLocalizations.of(context).t('language'), style: tt.bodyMedium),
                      subtitle: Text(
                        _selectedLanguage,
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(AppLocalizations.of(context).t('select_language'), style: tt.titleMedium),
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
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: Text(AppLocalizations.of(context).t('cancel')),
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
                      AppLocalizations.of(context).t('privacy'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.lock, color: muted),
                      title: Text(AppLocalizations.of(context).t('privacy_policy'), style: tt.bodyMedium),
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
                      title: Text(AppLocalizations.of(context).t('terms_of_service'), style: tt.bodyMedium),
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
                          title: Text(AppLocalizations.of(context).t('logout')),
                          content: Text(AppLocalizations.of(context).t('logout_confirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: Text(AppLocalizations.of(context).t('cancel'), style: tt.bodyMedium),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: Text(AppLocalizations.of(context).t('logout'), style: tt.bodyMedium),
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
                  icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onError),
                  label: Text(AppLocalizations.of(context).t('logout'), style: tt.bodyMedium),
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

