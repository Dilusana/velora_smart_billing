import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../orders/order_providers.dart';
import '../../products/product_providers.dart';

class BestSellingProductsPanel extends ConsumerWidget {
  const BestSellingProductsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(firestoreOrdersProvider);
    final productsAsync = ref.watch(firestoreProductsProvider);

    final orders = ordersAsync.value ?? [];
    final allProducts = productsAsync.value ?? [];

    final Map<String, Map<String, dynamic>> productStats = {};

    for (final order in orders) {
      for (final item in order.items) {
        final id = item.productId.isNotEmpty ? item.productId : item.productName;
        final name = item.productName.isNotEmpty ? item.productName : item.productId;
        final qty = item.quantity;

        if (!productStats.containsKey(id)) {
          productStats[id] = {'id': id, 'name': name, 'units': 0};
        }
        productStats[id]!['units'] = (productStats[id]!['units'] as int) + qty;
      }
    }

    final colors = [
      AppColors.primary,
      AppColors.accentTeal,
      AppColors.accentGold,
      AppColors.accentOrange,
      AppColors.accentPurple,
    ];

    List<Map<String, dynamic>> sortedList = productStats.values.toList();
    sortedList.sort((a, b) => (b['units'] as int).compareTo(a['units'] as int));

    if (sortedList.isEmpty) {
      sortedList = allProducts.take(5).map((p) => {
        'id': p.id,
        'name': p.name,
        'units': p.stock,
      }).toList();
    } else {
      sortedList = sortedList.take(5).toList();
    }

    for (int i = 0; i < sortedList.length; i++) {
      sortedList[i]['color'] = colors[i % colors.length];
    }

    final maxUnits = sortedList.isNotEmpty
        ? sortedList.map((e) => (e['units'] as int) > 0 ? e['units'] as int : 1).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Selling Products',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  try {
                    context.go('/products');
                  } catch (e) {}
                },
                child: Text(
                  'View All →',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (sortedList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('No product sales data available', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...sortedList.map((p) => _buildProductRow(context, p, maxUnits, isDark)),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, Map<String, dynamic> product, int maxUnits, bool isDark) {
    final units = product['units'] as int;
    final color = product['color'] as Color;

    return InkWell(
      onTap: () => context.go('/products/${product["id"]}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                product['name'] as String,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0, end: maxUnits > 0 ? (units / maxUnits) : 0),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              child: Text(
                '$units units',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
