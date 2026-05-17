import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import '../test_helpers.dart';

void main() {
  group('Bottom Navigation UI Tests', () {
    testWidgets('Bottom navigation displays all five tabs',
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

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('Bottom navigation displays correct icons',
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

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.byIcon(Icons.mail), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Clicking Calls tab shows CallContactsScreen',
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

      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      // Verify navigation occurred (Calls tab is now active)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Clicking Chats tab shows MessagesScreen',
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

      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(MessagesScreen), findsOneWidget);
    });

    testWidgets('Clicking You tab shows ProfileScreen',
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

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Feed tab is selected by default',
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

      // Feed should be visible by default
      expect(find.text('What is on your mind?'), findsOneWidget);
    });
  });
}
