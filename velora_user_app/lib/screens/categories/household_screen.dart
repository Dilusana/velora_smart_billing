import 'package:flutter/material.dart';
import '../category_screen.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(categoryLabel: 'Household');
  }
}
