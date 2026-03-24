import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../widets/custom_textfield.dart';
import 'home/chat_list_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String email = '';
  String password = '';

  bool isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? error = await _authService.login(email: email, password: password);

    setState(() => isLoading = false);

    if (error == null) {
      // ✅ Go to chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatListScreen()),
      );
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
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Classmate",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Welcome back"),

                SizedBox(height: 30),

                CustomTextField(
                  label: "Email",
                  onChanged: (val) => email = val,
                  validator: Validators.validateEmail,
                ),

                SizedBox(height: 15),

                CustomTextField(
                  label: "Password",
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: Validators.validatePassword,
                ),

                SizedBox(height: 25),

                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text("Login"),
                      ),

                SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  child: Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
