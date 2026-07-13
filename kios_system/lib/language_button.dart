import 'package:flutter/material.dart';

/// A pill-shaped language selector button used in the header.
///
/// Shows a check style highlight when [selected] is true.
class LanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const LanguageButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF1B8A3D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? green : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? green : const Color(0xFFE0E0E0),
              width: 1.4,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: green.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF424242),
            ),
          ),
        ),
      ),
    );
  }
}
