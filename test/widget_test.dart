import 'package:classmate_app_1/screens/auth_gate.dart';
import 'package:classmate_app_1/widets/custom_textfield.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthGate shows login screen when signed out', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockFirebaseAuth(signedIn: false);

    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

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
  });
}
