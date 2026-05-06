import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/notification_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('Notification Feature Tests', () {
    testWidgets('Notification icon is clickable on feed page',
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

      final notificationIcon = find.byIcon(Icons.notifications);
      expect(notificationIcon, findsOneWidget);

      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      // Verify NotificationScreen is shown
      expect(find.byType(NotificationScreen), findsOneWidget);
    });

    testWidgets('Notification icon navigates to NotificationScreen',
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

      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationScreen), findsOneWidget);
    });

    testWidgets('Notification screen can be popped to return to feed',
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

      // Navigate to notifications
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationScreen), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on home
      expect(find.text('What is on your mind?'), findsOneWidget);
    });

    testWidgets('Notification icon only appears on feed page',
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

      // Check pages where notification should not appear
      final testPages = ['Calls', 'Communities', 'Chats', 'You'];

      for (final page in testPages) {
        await tester.tap(find.text(page));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.notifications),
          findsNothing,
          reason: 'Notification icon should not appear on $page page',
        );

        if (page != 'You') {
          // Go back to feed for next iteration
          await tester.tap(find.text('Feed'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Multiple notification taps navigate correctly',
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

      // First tap
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationScreen), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Second tap
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationScreen), findsOneWidget);
    });
  });
}
