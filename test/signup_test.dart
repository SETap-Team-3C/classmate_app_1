import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/screens/auth_screen.dart';

void main() {
  testWidgets('Signup Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.tap(find.text('Create a new account'));
    await tester.pump();

    // Check UI elements
    expect(find.text("Sign Up"), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    // Enter valid data
    await tester.enterText(find.byType(TextField).at(0), 'John');
    await tester.enterText(find.byType(TextField).at(1), 'john@test.com');
    await tester.enterText(find.byType(TextField).at(2), '123456');

    // Tap button
    await tester.tap(find.text("Create Account"));
    await tester.pump();
  });
}
