import 'package:classmate_app_1/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('ProfileScreen save shows snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const ProfileScreen()));

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alice');
    await tester.enterText(find.widgetWithText(TextField, 'Bio'), 'Student');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.textContaining('Saved profile'), findsOneWidget);
  });
}
