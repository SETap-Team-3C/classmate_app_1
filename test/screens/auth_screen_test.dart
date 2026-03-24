import 'package:classmate_app_1/screens/auth_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('AuthScreen toggles between login and signup', (
    WidgetTester tester,
  ) async {
    final auth = MockFirebaseAuth();

    await tester.pumpWidget(
      wrapForTest(AuthScreen(auth: auth)),
    );

    expect(find.text('Username | Email'), findsOneWidget);
    expect(find.text('Username'), findsNothing);

    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });

  testWidgets('AuthScreen shows required fields snackbar', (
    WidgetTester tester,
  ) async {
    final auth = MockFirebaseAuth();

    await tester.pumpWidget(
      wrapForTest(AuthScreen(auth: auth)),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Please fill all required fields.'), findsOneWidget);
  });
}
