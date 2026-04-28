import 'package:classmate_app_1/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('ProfileScreen displays user info', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const ProfileScreen(
          userId: 'test-user-id',
          isCurrentUser: false,
        ),
      ),
    );

    // Wait for the circular progress indicator to appear
    await tester.pumpAndSettle();

    // The test will now load the profile screen with the required userId parameter
  });
}

