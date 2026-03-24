// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
chatbox
import 'package:classmate_app_1/screens/auth_gate.dart';

void main() {
  testWidgets('AuthGate shows login screen when signed out', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockFirebaseAuth(signedIn: false);

    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));

    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
import 'package:classmate_app_1/widets/custom_textfield.dart';

void main() {
  testWidgets('CustomTextField renders and accepts input', (
    WidgetTester tester,
  ) async {
    String latest = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: CustomTextField(
              label: 'Email',
              onChanged: (value) => latest = value,
              validator: (value) => null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(latest, 'test@example.com');
    main
  });
}
