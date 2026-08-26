import 'package:flutter/material.dart';
import '../category_screen.dart';

class GroceriesScreen extends StatelessWidget {
  const GroceriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(categoryLabel: 'Groceries');
  }
}
