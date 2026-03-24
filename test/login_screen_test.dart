import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    expect(find.text("Login"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), "test@mail.com");
    await tester.enterText(find.byType(TextFormField).at(1), "123456");

    await tester.tap(find.text("Login"));
    await tester.pump();
  });
}
