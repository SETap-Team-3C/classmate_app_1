import 'package:classmate_app_1/screens/messages_screen.dart';
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
  });

  testWidgets('Search User functionality - placeholder', (
    WidgetTester tester,
  ) async {
    // Placeholder for search user sheet tests
    expect(true, true);
  });
}

