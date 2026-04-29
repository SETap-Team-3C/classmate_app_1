import 'package:classmate_app_1/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('Delete option asks confirmation then runs callback', (
    WidgetTester tester,
  ) async {
    var deleted = false;

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: MessageBubble(
            messageId: 'm1',
            text: 'Delete me',
            isCurrentUser: true,
            isRead: false,
            readStatusText: 'unseen',
            onDeleteForMe: () async {
              deleted = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to delete your message?'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
