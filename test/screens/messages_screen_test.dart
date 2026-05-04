import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('MessagesScreen renders empty state in test mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(MessagesScreen(showTestEmptyState: true, themeProvider: ThemeProvider())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Direct Messages'), findsOneWidget);
    expect(find.text('No chats yet. Tap + to start one.'), findsOneWidget);
  });

  testWidgets('Search User sheet filters by name and username', (
    WidgetTester tester,
  ) async {
    String? selectedUserId;

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: UserSearchBottomSheet(
            currentUserId: 'u1',
            usersLoader: () async => const [
              SearchUser(
                id: 'u1',
                name: 'Alice',
                username: 'alice',
                email: 'alice@test.com',
              ),
              SearchUser(
                id: 'u2',
                name: 'Bob',
                username: 'bobby',
                email: 'bob@test.com',
              ),
              SearchUser(
                id: 'u3',
                name: 'Charlie',
                username: 'charlie',
                email: 'charlie@test.com',
              ),
            ],
            onUserSelected: (user) async {
              selectedUserId = user.id;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search User'), findsOneWidget);
    expect(find.text('Search by name or username'), findsOneWidget);

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'bobb');
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsNothing);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(selectedUserId, 'u2');
  });
}
