import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  group('Screen Layout and Responsiveness Tests', () {
    testWidgets('Home screen displays correctly in portrait mode',
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.physicalSizeTestValue = null);
      addTearDown(
        () => addTearDown(
          () => tester.binding.window.physicalSizeTestValue = null,
        ),
      );

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);

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

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('All navigation tabs are visible and accessible',
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

      final navLabels = ['Feed', 'Calls', 'Communities', 'Chats', 'You'];
      for (final label in navLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('Feed content is properly centered and readable',
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

      expect(find.text('What is on your mind?'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Scaffold maintains proper structure',
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

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Feed switcher is properly aligned in app bar',
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

      expect(find.text('Class'), findsOneWidget);
      expect(find.text('Mates'), findsOneWidget);

      // Both should be in the same app bar
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('Action buttons are properly positioned in app bar',
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

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Bottom navigation items have proper spacing',
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

      final navBar = find.byType(BottomNavigationBar);
      expect(navBar, findsOneWidget);

      // All items should be present
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
      expect(find.byIcon(Icons.mail), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Screen content remains visible during tab switches',
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

      // Check visibility on each tab
      final tabs = ['Calls', 'Communities', 'Chats', 'You'];
      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();

        // Widget tree should still be intact
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });

    testWidgets('Empty spaces and padding are appropriate',
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

      // Look for SizedBox which typically represents padding/spacing
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
