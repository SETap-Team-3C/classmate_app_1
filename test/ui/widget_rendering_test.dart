import 'package:classmate_app_1/widets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Rendering Tests', () {
    testWidgets('AppLogo renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('AppLogo is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('AppLogo displays image', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have image widget
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Multiple AppLogos can render together',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                AppLogo(),
                AppLogo(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsWidgetCount(2));
    });

    testWidgets('AppLogo in different contexts renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppLogo(),
                    SizedBox(height: 100),
                    AppLogo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsWidgetCount(2));
    });

    testWidgets('Scaffold with AppLogo maintains layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Test')),
            body: Center(
              child: AppLogo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('AppLogo responds to size constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: AppLogo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('AppLogo in containers renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: const AppLogo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });
  });
}
