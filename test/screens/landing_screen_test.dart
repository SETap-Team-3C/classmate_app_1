import 'package:classmate_app_1/screens/auth/home/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('LandingScreen shows branding and opens login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const LandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Classmate'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
