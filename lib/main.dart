import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

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
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _languageProvider.loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageInherited(
      languageProvider: _languageProvider,
      child: AnimatedBuilder(
        animation: _themeProvider,
        builder: (context, _) {
          final languageProvider = LanguageInherited.of(context);
          return MaterialApp(
            title: 'Classmate',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizationsDelegate(),
            ],
            theme: _themeProvider.lightTheme,
            darkTheme: _themeProvider.darkTheme,
            themeMode:
                _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: WelcomeScreen(themeProvider: _themeProvider),
          );
        },
      ),
    );
  }
}

