import 'package:flutter_test/flutter_test.dart';

import 'package:speakflow/main.dart';

void main() {
  testWidgets('SpeakFlow app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpeakFlowApp());

    // Verify that the title is rendered.
    expect(find.text('SpeakFlow'), findsOneWidget);
  });
}
