import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/auth/home/landing_screen.dart';

void main() async {
  // Ensures Flutter is ready before Firebase starts
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Initializing Firebase...');
    debugPrint('Project ID: classmates1project');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    debugPrint('Auth instance: ${FirebaseAuth.instance}');
    debugPrint('Current user: ${FirebaseAuth.instance.currentUser}');

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

class ClassmateApp extends StatefulWidget {
  const ClassmateApp({super.key});

  @override
  State<ClassmateApp> createState() => _ClassmateAppState();
}

class _ClassmateAppState extends State<ClassmateApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) => MaterialApp(
        title: 'Classmate',
        debugShowCheckedModeBanner: false,
        theme: _themeProvider.lightTheme,
        darkTheme: _themeProvider.darkTheme,
        themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: AuthGate(themeProvider: _themeProvider),
      ),
    );
  }
}
