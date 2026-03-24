import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.auth});

  final FirebaseAuth? auth;

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
          return const HomeScreen(title: 'Classmate Home');
        }

        return const AuthScreen();
      },
    );
  }
}