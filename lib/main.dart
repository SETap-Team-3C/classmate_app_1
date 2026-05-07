import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'core/language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth_gate.dart';

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
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  await languageProvider.loadLocale();
  runApp(
    ClassmateApp(
      themeProvider: themeProvider,
      languageProvider: languageProvider,
      home: AuthGate(themeProvider: themeProvider),
    ),
  );
}

class ClassmateApp extends StatefulWidget {
  const ClassmateApp({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
    required this.home,
  });

  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;
  final Widget home;

  @override
  State<ClassmateApp> createState() => _ClassmateAppState();
}

class _ClassmateAppState extends State<ClassmateApp> {
  @override
  Widget build(BuildContext context) {
    return LanguageInherited(
      languageProvider: widget.languageProvider,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.themeProvider,
          widget.languageProvider,
        ]),
        builder: (context, _) => MaterialApp(
          title: 'Classmate',
          debugShowCheckedModeBanner: false,
          locale: widget.languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('zh'),
            Locale('hi'),
            Locale('fr'),
          ],
          theme: widget.themeProvider.lightTheme,
          darkTheme: widget.themeProvider.darkTheme,
          themeMode: widget.themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: widget.home,
        ),
      ),
    );
  }
}
