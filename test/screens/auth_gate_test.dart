import 'package:classmate_app_1/screens/auth_gate.dart';
import 'package:classmate_app_1/screens/auth_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('AuthGate shows AuthScreen when signed out', (
    WidgetTester tester,
  ) async {
    final auth = MockFirebaseAuth();

    await tester.pumpWidget(wrapForTest(AuthGate(auth: auth)));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
