import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../customers/customer_providers.dart';
import '../orders/order_providers.dart';
import '../products/product_providers.dart';
import 'widgets/best_selling_panel.dart';
import 'widgets/kpi_card.dart';
import 'widgets/payment_summary_panel.dart';
import 'widgets/revenue_distribution_panel.dart';
import 'widgets/sales_analytics_panel.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(isDark),
            const SizedBox(height: 20),
            _buildKpiCardsRow(ref),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: SalesAnalyticsPanel()),
                const SizedBox(width: 24),
                const Expanded(flex: 2, child: RevenueDistributionPanel()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: BestSellingProductsPanel()),
                const SizedBox(width: 24),
                const Expanded(flex: 2, child: PaymentSummaryPanel()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Admin!',
          style: GoogleFonts.inter(
            textStyle: AppTextStyles.headlineLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is what\'s happening with your store today.',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCardsRow(WidgetRef ref) {
    final ordersAsync = ref.watch(firestoreOrdersProvider);
    final productsAsync = ref.watch(firestoreProductsProvider);
    final customersAsync = ref.watch(firestoreCustomersProvider);

    final orders = ordersAsync.value ?? [];
    final products = productsAsync.value ?? [];
    final customers = customersAsync.value ?? [];

    final now = DateTime.now();

    // 1. Total sales & orders (all-time)
    final totalSales = orders.fold<double>(0.0, (sum, o) => sum + o.total);
    final totalOrdersCount = orders.length;

    // Low stock count
    final lowStockCount = products.where((p) => p.stock <= 10).length;

    // Monthly revenue
    final monthlyOrders = orders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month).toList();
    final monthlyRevenue = monthlyOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        KpiCard(
          title: "TOTAL SALES",
          value: formatCurrency.format(totalSales),
          delta: 'All time',
          deltaColor: AppColors.statusGreen,
          deltaBgColor: AppColors.statusGreenBg,
          icon: Icons.point_of_sale,
          accentColor: AppColors.statusGreen,
          targetRoute: '/orders',
        ),
        KpiCard(
          title: "TOTAL ORDERS",
          value: '$totalOrdersCount',
          delta: 'All time',
          deltaColor: AppColors.statusGreen,
          deltaBgColor: AppColors.statusGreenBg,
          icon: Icons.receipt_long,
          accentColor: AppColors.accentTeal,
          targetRoute: '/orders',
        ),
        KpiCard(
          title: "TOTAL PRODUCTS",
          value: NumberFormat('#,##0').format(products.length),
          delta: '',
          deltaColor: Colors.transparent,
          deltaBgColor: Colors.transparent,
          icon: Icons.inventory_2,
          accentColor: AppColors.accentOrange,
          targetRoute: '/products',
        ),
        KpiCard(
          title: "LOW STOCK",
          value: '$lowStockCount',
          delta: lowStockCount > 0 ? 'Urgent' : 'Normal',
          deltaColor: lowStockCount > 0 ? AppColors.statusRed : AppColors.statusGreen,
          deltaBgColor: lowStockCount > 0 ? AppColors.statusRedBg : AppColors.statusGreenBg,
          icon: Icons.warning_amber,
          accentColor: lowStockCount > 0 ? AppColors.statusRed : AppColors.statusGreen,
          targetRoute: '/inventory?filter=low_stock',
        ),
        KpiCard(
          title: "CUSTOMERS",
          value: NumberFormat('#,##0').format(customers.length),
          delta: customers.isNotEmpty ? '+${customers.length} total' : '0',
          deltaColor: AppColors.statusBlue,
          deltaBgColor: AppColors.statusBlueBg,
          icon: Icons.people,
          accentColor: AppColors.accentPurple,
          targetRoute: '/customers',
        ),
        KpiCard(
          title: "MONTHLY REVENUE",
          value: formatCurrency.format(monthlyRevenue),
          delta: 'This month',
          deltaColor: AppColors.statusGreen,
          deltaBgColor: AppColors.statusGreenBg,
          icon: Icons.trending_up,
          accentColor: AppColors.accentMint,
          targetRoute: '/reports',
        ),
      ],
    );
  }
}

