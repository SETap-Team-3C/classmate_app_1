import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/home/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Allow startup without Firebase config for local/web preview.
  }

  runApp(ClassmateApp());
}

class ClassmateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Classmate',

      // 🔥 Auto login check
      home:
          (Firebase.apps.isNotEmpty &&
              FirebaseAuth.instance.currentUser != null)
          ? ChatListScreen()
          : LoginScreen(),
    );
  }
}
