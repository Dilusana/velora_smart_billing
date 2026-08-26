import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retailnova/main.dart';
import 'package:retailnova/welcome_screen.dart';

void main() {
  testWidgets('App builds and shows welcome content', (WidgetTester tester) async {
    await tester.pumpWidget(const RetailNovaApp());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Welcome!'),
      ),
      findsOneWidget,
    );
  });
}
