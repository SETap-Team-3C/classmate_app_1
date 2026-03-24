import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('MessagesScreen renders empty state in test mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(const MessagesScreen(showTestEmptyState: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Direct Messages'), findsOneWidget);
    expect(find.text('No chats yet. Tap + to start one.'), findsOneWidget);
  });
}
