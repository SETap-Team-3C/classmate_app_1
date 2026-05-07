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
      debugPrint(
        '[authStateChanges] currentUser: ${FirebaseAuth.instance.currentUser}',
      );
    });

    await FirebaseAnalytics.instance.logEvent(
      name: 'copilot_startup_test',
      parameters: {
        'platform': DefaultFirebaseOptions.currentPlatform.projectId,
      },
    );
    debugPrint('Analytics event logged');
  } catch (error) {
    debugPrint('Firebase initialization error: $error');
  }

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();

  runApp(
    ClassmateApp(
      themeProvider: themeProvider,
      languageProvider: languageProvider,
    ),
  );
}

class ClassmateApp extends StatefulWidget {
  const ClassmateApp({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
  });

  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  @override
  State<ClassmateApp> createState() => _ClassmateAppState();
}

class _ClassmateAppState extends State<ClassmateApp> {
  @override
  void initState() {
    super.initState();
    widget.languageProvider.loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageInherited(
      languageProvider: widget.languageProvider,
      child: AnimatedBuilder(
        animation: widget.themeProvider,
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
            theme: widget.themeProvider.lightTheme,
            darkTheme: widget.themeProvider.darkTheme,
            themeMode: widget.themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: WelcomeScreen(themeProvider: widget.themeProvider),
          );
        },
      ),
    );
  }
}

