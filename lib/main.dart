import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your new screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/home/chat_list_screen.dart';
// Kept from the main branch
import 'screens/profile_screen.dart';

void main() async {
  // Ensures Flutter is ready before Firebase starts
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // This prevents the app from crashing if Firebase isn't configured yet
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const ClassmateApp());
}

class ClassmateApp extends StatelessWidget {
  const ClassmateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Classmate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Logic: If a user is already signed in, go to Chat. Otherwise, Login.
      home: (FirebaseAuth.instance.currentUser != null)
          ? ChatListScreen()
          : LoginScreen(),
    );
  }
}