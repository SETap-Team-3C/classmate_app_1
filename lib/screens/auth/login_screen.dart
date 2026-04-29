import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
// import '../../widets/app_logo.dart'; // unused after switching to image asset
import '../../widets/custom_textfield.dart';
import 'home/chat_list_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  FirebaseAnalytics? _analytics;

  String email = '';
  String password = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenOpened();
    });
  }

  Future<void> _logScreenOpened() async {
    try {
      if (Firebase.apps.isEmpty) return;
      _analytics ??= FirebaseAnalytics.instance;
      await _analytics
          ?.logEvent(name: 'screen_opened', parameters: {'screen': 'login'})
          .timeout(const Duration(seconds: 5));
      print('Analytics event logged successfully');
    } catch (e) {
      print('Analytics logging failed: $e');
      // Don't block UI for analytics
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics ??= FirebaseAnalytics.instance;
        await _analytics?.logEvent(
          name: 'login_attempt',
          parameters: {'has_email': email.isNotEmpty ? 'true' : 'false'},
        );
      }

      print('Starting login with email: $email');

      // Add timeout to prevent infinite freeze
      final error = await _authService
          .login(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                'Login request timed out. Check your internet connection.',
          );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (error == null) {
        print('Login successful, navigating to chat list');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatListScreen(themeProvider: widget.themeProvider),
          ),
        );
        return;
      }

      // Show detailed error
      print('Login error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      print('Login exception: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/app_logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Classmate',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Welcome back'),
                  ],
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  label: 'Email',
                  onChanged: (val) => email = val,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  label: 'Password',
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 25),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
