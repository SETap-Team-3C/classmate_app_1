import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/call_screen.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Screen loads', (WidgetTester tester) async {
    final auth = MockFirebaseAuth();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          title: 'Classmate',
          auth: auth,
          unreadCountStream: const Stream<int>.empty(),
          messagesScreenBuilder: (_) => MessagesScreen(
            showTestEmptyState: true,
            themeProvider: ThemeProvider(),
          ),
          themeProvider: ThemeProvider(),
        ),
      ),
    );

    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Mates'), findsOneWidget);
    expect(find.text('What is on your mind?'), findsOneWidget);
  });

  testWidgets('Call Screen loads and toggles call state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CallScreen(userName: 'John')),
    );

    expect(find.text('Call with John'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Start Call'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();

    expect(find.text('End Call'), findsOneWidget);
  });
}
