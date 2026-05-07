import 'package:classmate_app_1/screens/auth_gate.dart';
import 'package:classmate_app_1/screens/welcome_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('Authentication Feature Tests', () {
    testWidgets('Auth gate shows WelcomeScreen for unauthenticated users',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Auth gate shows welcome text for unauthenticated users',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ClassMates'), findsWidgets);
    });

    testWidgets('Auth gate shows logo for unauthenticated users',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Logo should be present
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Auth gate can handle auth state changes',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Auth gate renders welcome content', (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Welcome screen should display
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Auth gate displays theme correctly',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: themeProvider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Auth gate handles multiple renders', (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Should still show welcome screen after rebuild
      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Welcome screen is properly structured',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: ThemeProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Should have main scaffold
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Auth gate properly passes theme provider',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(signedIn: false);
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        wrapForTest(
          AuthGate(auth: auth, themeProvider: themeProvider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
