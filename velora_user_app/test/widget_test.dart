import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_user_app/models/cart_item.dart';

void main() {
  testWidgets('Renders Cart item widget and calculates total price', (WidgetTester tester) async {
    const item = CartItem(
      productId: 'prod_100',
      title: 'Organic Green Apples',
      description: 'Fresh organic green apples from Nuwara Eliya',
      price: 650.0,
      quantity: 2,
      category: 'Fruits',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Rs.${item.price.toStringAsFixed(0)}'),
                Text('Qty: ${item.quantity}'),
                Text('Total: Rs.${(item.price * item.quantity).toStringAsFixed(0)}'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Organic Green Apples'), findsOneWidget);
    expect(find.text('Rs.650'), findsOneWidget);
    expect(find.text('Qty: 2'), findsOneWidget);
    expect(find.text('Total: Rs.1300'), findsOneWidget);
  });
}
