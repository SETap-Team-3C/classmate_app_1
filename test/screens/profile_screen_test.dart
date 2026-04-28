import 'package:classmate_app_1/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileScreen accepts userId parameter', (WidgetTester tester) async {
    // Simply verify the widget can be created with the required parameters
    // Full testing would require Firebase mocking which is complex
    const widget = ProfileScreen(
      userId: 'test-user-id',
      isCurrentUser: false,
    );

    expect(widget.userId, 'test-user-id');
    expect(widget.isCurrentUser, false);
  });
}
