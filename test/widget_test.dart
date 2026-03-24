// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:classmate_app_1/screens/auth_gate.dart';

void main() {
  testWidgets('AuthGate shows login screen when signed out', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockFirebaseAuth(signedIn: false);

    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));

    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
