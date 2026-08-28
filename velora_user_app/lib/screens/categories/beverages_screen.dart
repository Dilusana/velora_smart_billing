import 'package:flutter/material.dart';
import '../category_screen.dart';

class BeveragesScreen extends StatelessWidget {
  const BeveragesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(categoryLabel: 'Beverages');
  }
}
