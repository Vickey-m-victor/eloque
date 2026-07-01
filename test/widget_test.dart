import 'package:flutter_test/flutter_test.dart';

import 'package:eloque/main.dart';

void main() {
  testWidgets('Eloque app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EloqueApp());

    // Verify that the title is rendered.
    expect(find.text('Eloque'), findsOneWidget);
  });
}
