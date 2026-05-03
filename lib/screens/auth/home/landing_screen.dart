import 'package:flutter/material.dart';

import '../../../core/theme/theme_provider.dart';
import '../login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(themeProvider: themeProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Image.asset(
                      'assets/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Connect, chat, and stay in touch with classmates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openLogin(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
