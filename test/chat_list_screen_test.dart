import 'package:classmate_app_1/core/theme/theme_provider.dart';
import 'package:classmate_app_1/screens/call_screen.dart';
import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Home Screen loads', (WidgetTester tester) async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'alice@test.com'),
      signedIn: true,
    );
    await tester.pumpWidget(
      wrapForTest(
        HomeScreen(
          title: 'Classmate Home',
          auth: auth,
          unreadCountStream: const Stream<int>.empty(),
          messagesScreenBuilder: (_) => MessagesScreen(
            showTestEmptyState: true,
            themeProvider: ThemeProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classmate Home'), findsOneWidget);
    expect(find.text('Direct Messages'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
  });

  testWidgets('Call Screen loads and toggles call state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        CallScreen(
          userName: 'John',
          userPhone: '1234567890',
          launchFn: (uri) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Call with John'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('Open Dialer'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();

    expect(find.text('End Call'), findsOneWidget);
  });
}
