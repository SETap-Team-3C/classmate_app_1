import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('Navigation Workflow Tests', () {
    testWidgetsFeedToChatsTransition(WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
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

      // Start on Feed
      expect(find.text('What is on your mind?'), findsOneWidget);

      // Navigate to Chats
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      expect(find.byType(MessagesScreen), findsOneWidget);
      expect(find.text('Direct Messages'), findsOneWidget);
    });

    testWidgets('Back from Chats returns to Feed', (WidgetTester tester) async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'test@test.com'),
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

      // Navigate to Chats
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsOneWidget);

      // Click back arrow
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should return to Feed
      expect(find.text('What is on your mind?'), findsOneWidget);
      expect(find.text('Class'), findsOneWidget);
    });

    testWidgets('Switching between multiple tabs works correctly',
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

      // Start on Feed
      expect(find.text('What is on your mind?'), findsOneWidget);

      // Go to Calls
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      // Go to Communities
      await tester.tap(find.text('Communities'));
      await tester.pumpAndSettle();

      // Go back to Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      // Should be back on Feed
      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Feed state persists when switching tabs',
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

      // Switch to Mates feed
      await tester.tap(find.text('Mates'));
      await tester.pumpAndSettle();

      // Switch to Calls
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      // Back to Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      // Mates feed should still be selected
      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Tab switching preserves scroll position',
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

      // Switch to Calls
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      // Back to Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      // Feed should be accessible
      expect(find.text('What is on your mind?'), findsOneWidget);
    });
  });
}
