import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app_1/screens/home_screen.dart';

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

    expect(find.text("Classmate Home"), findsOneWidget);
    expect(find.text('Welcome to Classmate App'), findsOneWidget);
import 'package:classmate_app_1/screens/auth/home/chat_list_screen.dart';

void main() {
  testWidgets('Chat List Screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ChatListScreen()));

    expect(find.text("Classmate"), findsOneWidget);
  });
}
