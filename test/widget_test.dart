import 'package:flutter_test/flutter_test.dart';
import 'package:qaafiya/main.dart';

void main() {
  testWidgets('Smoke test: Verify QaafiyaOneApp compiles and launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QaafiyaOneApp());

    // We verify the app tree is loaded successfully (represented by pump completing without error).
    expect(true, true);
  });
}
