import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../widets/custom_textfield.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String name = '';
  String email = '';
  String password = '';

  bool isLoading = false;

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? error = await _authService.signup(
      name: name,
      email: email,
      password: password,
    );

    setState(() => isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup Successful")));
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
                Text("Create your account"),

                SizedBox(height: 30),

                CustomTextField(
                  label: "Full Name",
                  onChanged: (val) => name = val,
                  validator: Validators.validateName,
                ),

                SizedBox(height: 15),

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
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text("Sign Up"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
