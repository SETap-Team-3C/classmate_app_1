import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.auth,
    this.firestore,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;

  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$');
    return usernameRegex.hasMatch(username);
  }

  bool _isAdminUsername(String username) {
    final normalized = username.toLowerCase();
    return normalized == 'bot1' || normalized == 'bot2';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final username = _nameController.text.trim();

    if (identifier.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        String emailForLogin = identifier;

        if (!identifier.contains('@')) {
          if (!_isValidUsername(identifier)) {
            throw FirebaseAuthException(
              code: 'invalid-username',
              message:
                  'Username can only use letters, numbers, and underscores. Underscores cannot be first or last.',
            );
          }

          QuerySnapshot<Map<String, dynamic>> usernameQuery;
          try {
            usernameQuery = await _firestore
                .collection('users')
                .where('usernameLower', isEqualTo: identifier.toLowerCase())
                .limit(1)
                .get();
          } on FirebaseException catch (_) {
            throw FirebaseAuthException(
              code: 'permission-denied',
              message:
                  'Username login needs Firestore read access. Temporarily log in with email, or update rules for username lookup.',
            );
          }

          if (usernameQuery.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with that username.',
            );
          }

          emailForLogin = (usernameQuery.docs.first.data()['email'] ?? '').toString();
          if (emailForLogin.isEmpty) {
            throw FirebaseAuthException(
              code: 'invalid-email',
              message: 'Account email is missing for this username.',
            );
          }
        }

        final credential = await _auth.signInWithEmailAndPassword(
          email: emailForLogin,
          password: password,
        );

        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        final existingName = (userDoc.data()?['name'] ?? '').toString();
        final fallbackName = emailForLogin.split('@').first;
        final resolvedName = existingName.isEmpty ? fallbackName : existingName;

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': resolvedName,
          'email': emailForLogin,
          'usernameLower': resolvedName.toLowerCase(),
          'isAdmin': _isAdminUsername(resolvedName),
        }, SetOptions(merge: true));
      } else {
        if (identifier.isEmpty || !identifier.contains('@')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email for sign up.',
          );
        }

        if (!_isValidUsername(username)) {
          throw FirebaseAuthException(
            code: 'invalid-username',
            message:
                'Username can only use letters, numbers, and underscores. Underscores cannot be first or last.',
          );
        }

        final usernameLower = username.toLowerCase();

        final credential =
            await _auth.createUserWithEmailAndPassword(
          email: identifier,
          password: password,
        );

        try {
          final usernameTaken = await _firestore
              .collection('users')
              .where('usernameLower', isEqualTo: usernameLower)
              .limit(1)
              .get();

          final takenByAnother = usernameTaken.docs.any(
            (doc) => doc.id != credential.user!.uid,
          );

          if (takenByAnother) {
            await credential.user?.delete();
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'username-already-in-use',
              message: 'That username is already taken. Please choose another.',
            );
          }

          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set({
            'name': username,
            'email': identifier,
            'usernameLower': usernameLower,
            'isAdmin': _isAdminUsername(username),
          }, SetOptions(merge: true));
        } on FirebaseException catch (error) {
          await credential.user?.delete();
          await _auth.signOut();
          throw FirebaseAuthException(
            code: error.code,
            message: error.message ?? 'Could not create account profile.',
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
    } on FirebaseException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            TextField(
              controller: _identifierController,
              keyboardType:
                  _isLogin ? TextInputType.text : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isLogin ? 'Username | Email' : 'Email',
              ),
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
                child: Text(_isLogin ? 'Login' : 'Create Account'),
              ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? 'Create a new account'
                    : 'I already have an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}