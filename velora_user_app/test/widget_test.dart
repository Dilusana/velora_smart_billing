// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:velora_user_app/main.dart';

void main() {
  testWidgets('VeloraApp splash screen renders smoke test', (WidgetTester tester) async {
    // Build VeloraApp and trigger initial frame.
    await tester.pumpWidget(const VeloraApp());

    // Verify that the splash screen displays VELORA title and tagline.
    expect(find.text('VELORA'), findsOneWidget);
    expect(find.text('Freshness. Simplified.'), findsOneWidget);

    // Complete pending splash screen delayed timers
    await tester.pump(const Duration(seconds: 4));
  });
}
