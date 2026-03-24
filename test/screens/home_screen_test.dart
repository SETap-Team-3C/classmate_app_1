import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('HomeScreen opens MessagesScreen from mail icon', (
    WidgetTester tester,
  ) async {
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
          messagesScreenBuilder: (_) => const MessagesScreen(
            showTestEmptyState: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mail));
    await tester.pumpAndSettle();

    expect(find.byType(MessagesScreen), findsOneWidget);
    expect(find.text('Direct Messages'), findsOneWidget);
  });
}
