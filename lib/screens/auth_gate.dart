import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/theme_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.auth, this.themeProvider});

  final FirebaseAuth? auth;
  final ThemeProvider? themeProvider;

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = auth ?? FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(
            title: 'Classmates',
            themeProvider: themeProvider ?? ThemeProvider(),
          );
        }

        return themeProvider == null ? const AuthScreen() : const WelcomeScreen();
      },
    );
  }
}
