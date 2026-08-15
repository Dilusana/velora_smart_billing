import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../orders/order_providers.dart';
import '../../../core/data/models.dart';

class SalesAnalyticsPanel extends ConsumerStatefulWidget {
  const SalesAnalyticsPanel({super.key});

  @override
  ConsumerState<SalesAnalyticsPanel> createState() => _SalesAnalyticsPanelState();
}

class _SalesAnalyticsPanelState extends ConsumerState<SalesAnalyticsPanel> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(firestoreOrdersProvider);
    final orders = ordersAsync.value ?? [];

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
                'Sales Analytics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              _buildToggleButtons(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: LineChart(
              _isWeekly ? _weeklyData(orders, isDark) : _monthlyData(orders, isDark),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTab('Weekly', _isWeekly),
          _buildTab('Monthly', !_isWeekly),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isWeekly = text == 'Weekly'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  LineChartData _weeklyData(List<OrderModel> orders, bool isDark) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final revenueByDay = List<double>.filled(7, 0.0);
    final ordersByDay = List<double>.filled(7, 0.0);
    final profitByDay = List<double>.filled(7, 0.0);

    for (final order in orders) {
      final diffDays = order.createdAt.difference(monday).inDays;
      if (diffDays >= 0 && diffDays < 7 && order.createdAt.year == monday.year) {
        revenueByDay[diffDays] += order.total;
        ordersByDay[diffDays] += 1;
        profitByDay[diffDays] += order.total * 0.3; // 30% estimated profit
      }
    }

    // Scale order count for chart visibility if small
    final scaledOrders = ordersByDay.map((cnt) => cnt * 1000).toList();

    double maxVal = 10000;
    for (final r in revenueByDay) {
      if (r > maxVal) maxVal = r;
    }
    maxVal = (maxVal * 1.2).clamp(10000, 500000);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxVal / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? AppColors.bgDarkBorder : AppColors.border,
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value.toInt() >= 0 && value.toInt() < days.length) {
                return Text(days[value.toInt()], style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12));
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              final kVal = value ~/ 1000;
              return Text('${kVal}k', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _createLineData(revenueByDay, AppColors.primary),
        _createLineData(scaledOrders, AppColors.accentTeal),
        _createLineData(profitByDay, AppColors.accentGold),
      ],
      minY: 0,
      maxY: maxVal,
    );
  }

  LineChartData _monthlyData(List<OrderModel> orders, bool isDark) {
    final now = DateTime.now();

    final revenueByMonth = List<double>.filled(12, 0.0);
    final ordersByMonth = List<double>.filled(12, 0.0);
    final profitByMonth = List<double>.filled(12, 0.0);

    for (final order in orders) {
      if (order.createdAt.year == now.year) {
        final mIdx = order.createdAt.month - 1;
        if (mIdx >= 0 && mIdx < 12) {
          revenueByMonth[mIdx] += order.total;
          ordersByMonth[mIdx] += 1;
          profitByMonth[mIdx] += order.total * 0.3;
        }
      }
    }

    final scaledOrders = ordersByMonth.map((cnt) => cnt * 1000).toList();

    double maxVal = 50000;
    for (final r in revenueByMonth) {
      if (r > maxVal) maxVal = r;
    }
    maxVal = (maxVal * 1.2).clamp(50000, 1000000);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxVal / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? AppColors.bgDarkBorder : AppColors.border,
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              if (value.toInt() >= 0 && value.toInt() < months.length) {
                return Text(months[value.toInt()], style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12));
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              final kVal = value ~/ 1000;
              return Text('${kVal}k', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _createLineData(revenueByMonth, AppColors.primary),
        _createLineData(scaledOrders, AppColors.accentTeal),
        _createLineData(profitByMonth, AppColors.accentGold),
      ],
      minY: 0,
      maxY: maxVal,
    );
  }

  LineChartBarData _createLineData(List<double> spots, Color color) {
    return LineChartBarData(
      spots: spots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Revenue', AppColors.primary, isDark),
        const SizedBox(width: 24),
        _buildLegendItem('Orders', AppColors.accentTeal, isDark),
        const SizedBox(width: 24),
        _buildLegendItem('Profit', AppColors.accentGold, isDark),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white70 : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
