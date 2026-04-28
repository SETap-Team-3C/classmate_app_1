import 'package:classmate_app_1/screens/home_screen.dart';
import 'package:classmate_app_1/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          title: 'Classmate Home',
          unreadCountStream: Stream<int>.empty(),
        ),
      ),
    );

    expect(find.text('Classmate Home'), findsOneWidget);
    expect(find.text('Welcome to Classmate App'), findsOneWidget);
  });

  testWidgets('Call Screen loads and toggles call state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CallScreen(userName: 'John')),
    );

    expect(find.text('Call with John'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Start Call'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();

    expect(find.text('End Call'), findsOneWidget);
  });
}
