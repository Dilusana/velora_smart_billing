import 'package:flutter/material.dart';
import '../category_screen.dart';

class FrozenFoodsScreen extends StatelessWidget {
  const FrozenFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(categoryLabel: 'Frozen Foods');
  }
}
