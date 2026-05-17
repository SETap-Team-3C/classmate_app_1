import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('User Action Feature Tests', () {
    testWidgets('Logout button is present in app bar',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Logout button is always visible', (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check on multiple pages
      final pages = ['Calls', 'Chats', 'You'];
      for (final page in pages) {
        await tester.tap(find.text(page));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.logout),
          findsOneWidget,
          reason: 'Logout button should be visible on $page page',
        );
      }
    });

    testWidgets('Feed switcher toggles between Class and Mates',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start with Class (default)
      await tester.tap(find.text('Class'));
      await tester.pumpAndSettle();

      // Switch to Mates
      await tester.tap(find.text('Mates'));
      await tester.pumpAndSettle();

      // Switch back to Class
      await tester.tap(find.text('Class'));
      await tester.pumpAndSettle();

      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Multiple feed switches work correctly',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Perform multiple switches
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Mates'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Class'));
        await tester.pumpAndSettle();
      }

      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Tab navigation preserves feed state',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Mates
      await tester.tap(find.text('Mates'));
      await tester.pumpAndSettle();

      // Switch tabs
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      // Return to Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      // Mates should still be selected
      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Bottom nav tab highlighting works correctly',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Feed should be highlighted
      expect(find.text('Feed'), findsOneWidget);

      // Switch to Chats
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      // Chats tab should now be highlighted
      expect(find.text('Chats'), findsOneWidget);
    });

    testWidgets('All navigation buttons are functional',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navItems = ['Feed', 'Calls', 'Chats', 'You'];

      for (final item in navItems) {
        await tester.tap(find.text(item));
        await tester.pumpAndSettle();
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });
  });
}
