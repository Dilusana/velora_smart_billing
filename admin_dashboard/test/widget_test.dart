import 'package:admin_dashboard/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VeloraApp builds without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VeloraApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
