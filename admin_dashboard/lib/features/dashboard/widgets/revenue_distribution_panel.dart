import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/category_provider.dart';
import '../../orders/order_providers.dart';

class RevenueDistributionPanel extends ConsumerStatefulWidget {
  const RevenueDistributionPanel({super.key});

  @override
  ConsumerState<RevenueDistributionPanel> createState() => _RevenueDistributionPanelState();
}

class _RevenueDistributionPanelState extends ConsumerState<RevenueDistributionPanel> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesFirestoreProvider);
    final ordersAsync = ref.watch(firestoreOrdersProvider);

    final categories = categoriesAsync.value ?? [];
    final orders = ordersAsync.value ?? [];

    final colors = [
      AppColors.primary,
      AppColors.accentTeal,
      AppColors.accentGold,
      AppColors.accentOrange,
      AppColors.accentPurple,
      Colors.blueGrey,
    ];

    final Map<String, double> categoryRevenue = {};

    double totalRevenue = 0.0;
    for (final order in orders) {
      totalRevenue += order.total;
    }

    if (categories.isNotEmpty && orders.isNotEmpty) {
      for (final category in categories) {
        categoryRevenue[category.name] = 0.0;
      }
      for (final order in orders) {
        for (final item in order.items) {
          final catName = categories.firstWhere(
            (c) => c.id == item.productId || c.name.toLowerCase() == item.productName.toLowerCase(),
            orElse: () => categories.first,
          ).name;
          categoryRevenue[catName] = (categoryRevenue[catName] ?? 0.0) + item.total;
        }
      }
    }

    List<Map<String, dynamic>> dataList = [];
    int colorIdx = 0;
    if (totalRevenue > 0 && categoryRevenue.isNotEmpty) {
      categoryRevenue.forEach((name, rev) {
        if (rev > 0) {
          final pct = (rev / totalRevenue * 100).roundToDouble();
          dataList.add({
            'name': name,
            'percent': pct > 0 ? pct : 1.0,
            'color': colors[colorIdx % colors.length],
            'category': name.toLowerCase(),
          });
          colorIdx++;
        }
      });
    }

    if (dataList.isEmpty) {
      dataList = categories.take(5).map((c) => {
        'name': c.name,
        'percent': (100 / (categories.isEmpty ? 1 : categories.length)).roundToDouble(),
        'color': colors[colorIdx++ % colors.length],
        'category': c.name.toLowerCase(),
      }).toList();
    }

    if (dataList.isEmpty) {
      dataList = [
        {'name': 'Vegetables', 'percent': 35.0, 'color': AppColors.primary, 'category': 'vegetables'},
        {'name': 'Grocery', 'percent': 25.0, 'color': AppColors.accentTeal, 'category': 'grocery'},
        {'name': 'Beverages', 'percent': 15.0, 'color': AppColors.accentGold, 'category': 'beverages'},
        {'name': 'Household', 'percent': 10.0, 'color': AppColors.accentOrange, 'category': 'household'},
        {'name': 'Others', 'percent': 15.0, 'color': Colors.grey, 'category': 'others'},
      ];
    }

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
          Text(
            'Revenue Distribution',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: List.generate(dataList.length, (i) {
                      final isTouched = i == touchedIndex;
                      final radius = isTouched ? 24.0 : 20.0;
                      return PieChartSectionData(
                        color: dataList[i]['color'] as Color,
                        value: dataList[i]['percent'] as double,
                        title: '',
                        radius: radius,
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '100%',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: dataList.map((item) => _buildLegendRow(item, isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Map<String, dynamic> item, bool isDark) {
    final pct = (item['percent'] as double).round();
    return InkWell(
      onTap: () {
        try {
          context.go('/products?category=${item["category"]}');
        } catch (e) {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                item['name'] as String,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item['percent'] as double) / 100,
                  backgroundColor: (item['color'] as Color).withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
