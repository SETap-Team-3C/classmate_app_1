import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('HomeScreen switches feed and opens MessagesScreen', (
    WidgetTester tester,
  ) async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'alice@test.com'),
      signedIn: true,
    );

    await tester.pumpWidget(
      wrapForTest(
        HomeScreen(
          title: 'Classmate',
          auth: auth,
          unreadCountStream: const Stream<int>.empty(),
          messagesScreenBuilder: (_) => MessagesScreen(
            showTestEmptyState: true,
            themeProvider: ThemeProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Mates'), findsOneWidget);
    expect(find.text('What is on your mind?'), findsOneWidget);

    await tester.tap(find.text('Mates'));
    await tester.pumpAndSettle();

    expect(find.text('What is on your mind?'), findsOneWidget);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();

    expect(find.byType(MessagesScreen), findsOneWidget);
    expect(find.text('Direct Messages'), findsOneWidget);
  });
}
