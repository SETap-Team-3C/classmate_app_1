import 'package:classmate_app_1/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full app test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Classmate'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'test@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }, skip: true);
}
