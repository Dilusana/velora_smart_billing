import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retailnova/app_theme.dart';
import 'package:retailnova/product_model.dart';

void main() {
  testWidgets('Renders product card with price and name accurately', (WidgetTester tester) async {
    const product = ProductModel(
      id: 'prod_test_01',
      name: 'Fresh Apples 1kg',
      category: 'Produce',
      description: 'Crisp and sweet fresh apples',
      price: 550.0,
      stock: 20,
      imageUrl: '',
      status: 'active',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Rs.${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.brand)),
                Text('In stock: ${product.stock}'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Fresh Apples 1kg'), findsOneWidget);
    expect(find.text('Rs.550'), findsOneWidget);
    expect(find.text('In stock: 20'), findsOneWidget);
  });
}
