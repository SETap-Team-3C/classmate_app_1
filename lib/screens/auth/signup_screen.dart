import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widets/app_logo.dart';
import '../../widets/custom_textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String name = '';
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? error = await _authService.signup(
      name: name,
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup Successful")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
                const AppLogo(
                  iconSize: 34,
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Create your account'),
                const SizedBox(height: 30),
                CustomTextField(
                  label: 'Full Name',
                  onChanged: (val) => name = val,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 15),
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
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Sign Up'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
