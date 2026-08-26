import 'package:flutter/material.dart';
import '../category_screen.dart';

class ChilledFoodsScreen extends StatelessWidget {
  const ChilledFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(categoryLabel: 'Chilled Foods');
  }
}
