import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<User?> _waitForAuthenticatedUser({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing;

    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(timeout);
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 15));

        final activeUser = await _waitForAuthenticatedUser();
        if (activeUser == null) {
          throw FirebaseAuthException(
            code: 'auth-not-ready',
            message:
                'Login completed but FirebaseAuth.currentUser is still null.',
          );
        }

        debugPrint('Login success UID: ${activeUser.uid}');
        debugPrint('Login success email: ${credential.user?.email}');
      } else {
        if (!email.contains('@')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email for sign up.',
          );
        }

        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 15));

        final activeUser = await _waitForAuthenticatedUser();
        if (activeUser == null) {
          throw FirebaseAuthException(
            code: 'auth-not-ready',
            message:
                'Signup completed but FirebaseAuth.currentUser is still null.',
          );
        }

        debugPrint('Signup success UID: ${activeUser.uid}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(activeUser.uid)
            .set({
          'uid': activeUser.uid,
          'name': fullName,
          'email': credential.user?.email ?? email,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));

        debugPrint('Signup Firestore profile created for UID: ${activeUser.uid}');
      }
<<<<<<< HEAD
=======

      final confirmedUser = FirebaseAuth.instance.currentUser;
      if (confirmedUser == null) {
        throw FirebaseAuthException(
          code: 'auth-not-ready',
          message: 'Authentication finished but currentUser is null.',
        );
      }

      debugPrint('Authenticated UID: ${confirmedUser.uid}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication successful')),
      );
    } on TimeoutException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Authentication timed out. Please try again.'),
        ),
      );
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
    } on FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('ClassMates'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
<<<<<<< HEAD
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.20),
=======
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.20),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/app_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ClassMates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            if (!_isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(_isLogin ? 'Login' : 'Create Account'),
              ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'Create a new account' : 'I already have an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
