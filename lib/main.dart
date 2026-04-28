import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'screens/auth/home/chat_list_screen.dart';
import 'screens/auth/home/landing_screen.dart';

void main() async {
  // Ensures Flutter is ready before Firebase starts
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    await FirebaseAnalytics.instance.logEvent(
      name: 'copilot_startup_test',
      parameters: {
        'platform': DefaultFirebaseOptions.currentPlatform.projectId,
      },
    );
    debugPrint('Analytics event logged');
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const ClassmateApp());
}

class ClassmateApp extends StatelessWidget {
  const ClassmateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While loading, show a splash screen or loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is logged in, show ChatListScreen
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint('User logged in: ${snapshot.data?.email}');
            return const ChatListScreen();
          }

          // If user is logged out, show the landing page.
          debugPrint('User logged out');
          return const LandingScreen();
        },
      ),
    );
  }
}
