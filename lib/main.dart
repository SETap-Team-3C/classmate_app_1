import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  
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

    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('[authStateChanges] event: $user');
      debugPrint('[authStateChanges] currentUser: ${FirebaseAuth.instance.currentUser}');
    });

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

  final themeProvider = ThemeProvider();
  runApp(ClassmateApp(themeProvider: themeProvider, home: const AuthScreen()));
}

class ClassmateApp extends StatefulWidget {
  const ClassmateApp({super.key, required this.themeProvider, required this.home});

  final ThemeProvider themeProvider;
  final Widget home;

  @override
  State<ClassmateApp> createState() => _ClassmateAppState();
}

class _ClassmateAppState extends State<ClassmateApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, _) => MaterialApp(
        title: 'Classmate',
        debugShowCheckedModeBanner: false,
        theme: widget.themeProvider.lightTheme,
        darkTheme: widget.themeProvider.darkTheme,
        themeMode: widget.themeProvider.isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        home: widget.home,
      ),
    );

  }
}
