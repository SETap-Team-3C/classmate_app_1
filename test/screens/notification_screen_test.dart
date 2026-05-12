import 'package:classmate_app_1/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('NotificationScreen show now updates list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const NotificationScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Ping');
    await tester.enterText(find.byType(TextField).at(1), 'Hello');
    await tester.tap(find.text('Show Now'));
    await tester.pump();

    expect(find.text('Ping: Hello'), findsOneWidget);
  });
}
