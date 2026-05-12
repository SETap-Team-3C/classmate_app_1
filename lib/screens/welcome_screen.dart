import 'package:flutter/material.dart';

import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.10),
                  cs.secondary.withValues(alpha: 0.05),
                  cs.surface,
                ],
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 26,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 44,
              color: cs.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 150,
            right: 24,
            child: Icon(
              Icons.message_outlined,
              size: 52,
              color: cs.secondary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 36,
            child: Icon(
              Icons.forum_outlined,
              size: 56,
              color: cs.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 90,
            right: 28,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 86,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: 22,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 320,
            right: 40,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withValues(alpha: 0.11),
              ),
            ),
          ),
          Positioned(
            bottom: 240,
            right: 78,
            child: Icon(
              Icons.more_horiz,
              size: 34,
              color: cs.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 210,
            left: 92,
            child: Icon(
              Icons.more_horiz,
              size: 28,
              color: cs.secondary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 410,
            left: 34,
            child: Container(
              width: 120,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: cs.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Positioned(
            top: 470,
            right: 20,
            child: Container(
              width: 96,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                color: cs.secondary.withValues(alpha: 0.05),
                border: Border.all(
                  color: cs.secondary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.20),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'ClassMates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Welcome to ClassMates',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Stay connected with your classmates',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openLogin(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Get Started / Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
