import 'package:classmate_app_1/screens/auth/home/landing_screen.dart';
<<<<<<< HEAD
=======
import 'package:classmate_app_1/core/theme/theme_provider.dart';
>>>>>>> d748d3d (improve UI)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classmate_app_1/core/theme/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  testWidgets('LandingScreen shows branding and opens login', (
    WidgetTester tester,
  ) async {
<<<<<<< HEAD
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      wrapForTest(LandingScreen(themeProvider: themeProvider)),
    );
=======
    await tester.pumpWidget(wrapForTest(LandingScreen(themeProvider: ThemeProvider())));
>>>>>>> d748d3d (improve UI)
    await tester.pumpAndSettle();
    expect(find.text('Connect, chat, and stay in touch with classmates.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

<<<<<<< HEAD
    expect(find.text('Classmate'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

=======
>>>>>>> d748d3d (improve UI)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
