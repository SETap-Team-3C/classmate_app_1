import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/screens/auth/signup_screen.dart';

void main() {
  testWidgets('Signup Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupScreen()));

    // Check UI elements
    expect(find.text("Classmate"), findsOneWidget);
    expect(find.text("Sign Up"), findsOneWidget);

    // Enter valid data
    await tester.enterText(find.byType(TextFormField).at(0), "John");
    await tester.enterText(find.byType(TextFormField).at(1), "john@test.com");
    await tester.enterText(find.byType(TextFormField).at(2), "123456");

    // Tap button
    await tester.tap(find.text("Sign Up"));
    await tester.pump();
  });
}
