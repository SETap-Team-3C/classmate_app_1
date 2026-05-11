import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/language_provider.dart';
import '../core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_activity_screen.dart';
import '../services/auth_service.dart';
import '../services/block_service.dart';
import 'auth/login_screen.dart';

import '../core/theme/theme_provider.dart';

import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class _BlockedUserEntry {
  _BlockedUserEntry({
    required this.userId,
    required this.displayName,
    required this.email,
  });

  final String userId;
  final String displayName;
  final String email;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BlockService _blockService = BlockService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = const [
    'English',
    'Spanish',
    'Chinese (Mandarin)',
    'Hindi',
    'French',
  ];
  bool _loadedLanguage = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedLanguage) return;
    _loadedLanguage = true;
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
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          ).t('selected_language_changed', params: {'language': language}),
        ),
      ),
    );
  }

  Future<List<_BlockedUserEntry>> _loadBlockedUsers(
    Set<String> blockedUserIds,
  ) async {
    if (blockedUserIds.isEmpty) return const [];

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final entries = await Future.wait(
      blockedUserIds.map((userId) async {
        final doc = await usersCollection.doc(userId).get();
        final data = doc.data() ?? <String, dynamic>{};
        final displayName = (data['displayName'] ?? data['name'] ?? 'User')
            .toString();
        final email = (data['email'] ?? '').toString();
        return _BlockedUserEntry(
          userId: userId,
          displayName: displayName,
          email: email,
        );
      }),
    );

    final sorted = entries.toList();
    sorted.sort((left, right) {
      final leftName = left.displayName.toLowerCase();
      final rightName = right.displayName.toLowerCase();
      return leftName.compareTo(rightName);
    });
    return sorted;
  }

  Future<void> _showBlockedUsersSheet() async {
    final loc = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: StreamBuilder<Set<String>>(
              stream: _blockService.watchBlockedUserIds(),
              builder: (context, blockedSnapshot) {
                final blockedUserIds = blockedSnapshot.data ?? <String>{};

                return FutureBuilder<List<_BlockedUserEntry>>(
                  future: _loadBlockedUsers(blockedUserIds),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final blockedUsers = usersSnapshot.data ?? const [];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('blocked_users'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.t('manage_blocked_users'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        if (blockedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(loc.t('no_blocked_users')),
                            ),
                          )
                        else
                          SizedBox(
                            height: 420,
                            child: ListView.separated(
                              itemCount: blockedUsers.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final user = blockedUsers[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(user.displayName),
                                  subtitle: user.email.isEmpty
                                      ? Text(user.userId)
                                      : Text(user.email),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      await _blockService.unblockUser(
                                        user.userId,
                                      );
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            loc.t('account_unblocked'),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(loc.t('unblock_account')),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).t('settings'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
                      title: Text(
                        AppLocalizations.of(context).t('email'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        user?.email ??
                            AppLocalizations.of(context).t('not_available'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.edit, color: muted),
                      title: Text(
                        AppLocalizations.of(context).t('edit_profile'),
                        style: tt.bodyMedium,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.devices, color: muted),
                      title: Text(
                        AppLocalizations.of(context).t('login_activity'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        ).t('login_activity_description'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
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
                      title: Text(
                        AppLocalizations.of(context).t('enable_notifications'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        ).t('receive_message_notifications'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      value: _notificationsEnabled,
                      activeThumbColor: cs.primary,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context).t('sound'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        ).t('play_notification_sound'),
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
                      title: Text(
                        AppLocalizations.of(context).t('theme'),
                        style: tt.bodyMedium,
                      ),
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
                            title: Text(
                              AppLocalizations.of(context).t('select_theme'),
                              style: tt.titleMedium,
                            ),
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
                                  title: Text(
                                    AppLocalizations.of(context).t('light'),
                                    style: tt.bodyMedium,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(context).t('dark'),
                                    style: tt.bodyMedium,
                                  ),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(
                                  AppLocalizations.of(context).t('cancel'),
                                ),
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
                      title: Text(
                        AppLocalizations.of(context).t('language'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        _selectedLanguage,
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context).t('select_language'),
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
                                child: Text(
                                  AppLocalizations.of(context).t('cancel'),
                                ),
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
                      title: Text(
                        AppLocalizations.of(context).t('privacy_policy'),
                        style: tt.bodyMedium,
                      ),
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
                      title: Text(
                        AppLocalizations.of(context).t('terms_of_service'),
                        style: tt.bodyMedium,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.block, color: muted),
                      title: Text(
                        AppLocalizations.of(context).t('blocked_users'),
                        style: tt.bodyMedium,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context).t('manage_blocked_users'),
                        style: tt.bodySmall?.copyWith(color: muted),
                      ),
                      onTap: _showBlockedUsersSheet,
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
                        content: Text(
                          AppLocalizations.of(context).t('logout_confirm'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(
                              AppLocalizations.of(context).t('cancel'),
                              style: tt.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(
                              AppLocalizations.of(context).t('logout'),
                              style: tt.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout != true) return;
                    await AuthService().logout();
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
                  label: Text(
                    AppLocalizations.of(context).t('logout'),
                    style: tt.bodyMedium,
                  ),
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
