import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/messages_screen.dart';
import 'package:classmate_app_1/screens/call_screen.dart';
import 'package:classmate_app_1/core/theme/theme_provider.dart';
<<<<<<< HEAD
=======
import 'package:classmate_app_1/screens/messages_screen.dart';
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Screen loads', (WidgetTester tester) async {
<<<<<<< HEAD
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'alice@test.com'),
      signedIn: true,
    );
=======
    final auth = MockFirebaseAuth();
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
<<<<<<< HEAD
          title: 'Classmate Home',
=======
          title: 'Classmate',
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
          auth: auth,
          unreadCountStream: const Stream<int>.empty(),
          messagesScreenBuilder: (_) => MessagesScreen(
            showTestEmptyState: true,
            themeProvider: ThemeProvider(),
          ),
<<<<<<< HEAD
=======
          themeProvider: ThemeProvider(),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
        ),
      ),
    );

<<<<<<< HEAD
    expect(find.text('Classmate Home'), findsOneWidget);
    expect(find.text('Direct Messages'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
=======
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Mates'), findsOneWidget);
    expect(find.text('What is on your mind?'), findsOneWidget);
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
  });

  testWidgets('Call Screen loads and toggles call state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CallScreen(
          userName: 'John',
          userPhone: '1234567890',
          launchFn: (uri) async => true,
        ),
      ),
    );

    expect(find.text('Call with John'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('Open Dialer'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();

    expect(find.text('End Call'), findsOneWidget);
  });
}
