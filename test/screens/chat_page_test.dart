import 'package:classmate_app_1/screens/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('ChatPage renders top bar and empty state in test mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
<<<<<<< HEAD
      wrapForTest(const ChatPage(receiverId: 'u2', receiverName: 'Bob')),
=======
      wrapForTest(
        const ChatPage(
          receiverId: 'u2',
          receiverName: 'Bob',
        ),
      ),
>>>>>>> d748d3d (improve UI)
    );
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(
      find.text('No messages yet. Start the conversation.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
