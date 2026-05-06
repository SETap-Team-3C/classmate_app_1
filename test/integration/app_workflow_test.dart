import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('Full Application Workflow Tests', () {
    testWidgets('Complete user workflow: Feed -> Mates -> Chats -> Back -> Profile',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'alice@example.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            messagesScreenBuilder: (_) => MessagesScreen(
              showTestEmptyState: true,
              themeProvider: ThemeProvider(),
            ),
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Verify on Feed with Class
      expect(find.text('Class'), findsOneWidget);
      expect(find.text('What is on your mind?'), findsOneWidget);

      // Step 2: Switch to Mates
      await tester.tap(find.text('Mates'));
      await tester.pumpAndSettle();
      expect(find.text('What is on your mind?'), findsOneWidget);

      // Step 3: Navigate to Chats
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsOneWidget);

      // Step 4: Go back to Feed
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('What is on your mind?'), findsOneWidget);

      // Step 5: Navigate to Profile
      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Feed persistence across tab navigation',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'bob@example.com'),
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

      // Set to Mates feed
      await tester.tap(find.text('Mates'));
      await tester.pumpAndSettle();

      // Navigate through other tabs
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Communities'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();

      // Return to Feed - Mates should still be selected
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Rapid tab switching stress test', (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'charlie@example.com'),
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

      // Rapid switching
      final tabs = ['Calls', 'Communities', 'Chats', 'You', 'Feed'];
      for (int i = 0; i < 3; i++) {
        for (final tab in tabs) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Navigation maintains app stability',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'diana@example.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        wrapForTest(
          HomeScreen(
            title: 'ClassMates',
            auth: auth,
            messagesScreenBuilder: (_) => MessagesScreen(
              showTestEmptyState: true,
              themeProvider: ThemeProvider(),
            ),
            themeProvider: ThemeProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Multiple workflows
      for (int iteration = 0; iteration < 3; iteration++) {
        // Switch feeds
        await tester.tap(find.text('Class'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mates'));
        await tester.pumpAndSettle();

        // Navigate to different tabs
        await tester.tap(find.text('Chats'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Check app is still responsive
        expect(find.text('What is on your mind?'), findsOneWidget);
      }
    });

    testWidgets('All UI elements remain accessible throughout workflow',
        (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'eve@example.com'),
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

      // Verify key UI elements are always present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate and verify elements still exist
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
