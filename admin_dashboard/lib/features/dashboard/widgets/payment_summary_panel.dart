import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../orders/order_providers.dart';
import '../../payments/payment_providers.dart';

class PaymentSummaryPanel extends ConsumerWidget {
  const PaymentSummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    final ordersAsync = ref.watch(firestoreOrdersProvider);
    final paymentsAsync = ref.watch(firestorePaymentsProvider);

    final orders = ordersAsync.value ?? [];
    final payments = paymentsAsync.value ?? [];

    double cashAmount = 0.0;
    double cardAmount = 0.0;
    double qrAmount = 0.0;

    if (payments.isNotEmpty) {
      for (final p in payments) {
        final m = p.paymentMethod.toLowerCase();
        if (m.contains('cash')) {
          cashAmount += p.amount;
        } else if (m.contains('card') || m.contains('online') || m.contains('pos')) {
          cardAmount += p.amount;
        } else if (m.contains('qr') || m.contains('upi') || m.contains('paytm') || m.contains('gpay')) {
          qrAmount += p.amount;
        } else {
          cashAmount += p.amount;
        }
      }
    } else {
      for (final o in orders) {
        final m = o.paymentMethod.toLowerCase();
        if (m.contains('cash')) {
          cashAmount += o.total;
        } else if (m.contains('card') || m.contains('online') || m.contains('pos')) {
          cardAmount += o.total;
        } else if (m.contains('qr') || m.contains('upi') || m.contains('paytm') || m.contains('gpay')) {
          qrAmount += o.total;
        } else {
          cashAmount += o.total;
        }
      }
    }

    final totalRevenue = cashAmount + cardAmount + qrAmount;

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
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    borderData: FlBorderData(show: false),
                    sections: [
                      PieChartSectionData(color: AppColors.primary, value: cashAmount > 0 ? cashAmount : 1, radius: 15, title: ''),
                      PieChartSectionData(color: AppColors.accentTeal, value: cardAmount > 0 ? cardAmount : 0.001, radius: 15, title: ''),
                      PieChartSectionData(color: AppColors.accentGold, value: qrAmount > 0 ? qrAmount : 0.001, radius: 15, title: ''),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildPaymentRow(context, 'Cash', cashAmount, Icons.money, AppColors.primary, isDark, currencyFormatter),
                    _buildPaymentRow(context, 'Card', cardAmount, Icons.credit_card, AppColors.accentTeal, isDark, currencyFormatter),
                    _buildPaymentRow(context, 'QR Payment', qrAmount, Icons.qr_code, AppColors.accentGold, isDark, currencyFormatter),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormatter.format(totalRevenue),
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context, String method, double amount, IconData icon, Color color, bool isDark, NumberFormat formatter) {
    return InkWell(
      onTap: () {
        try {
          context.go('/payments?method=${method.toLowerCase().replaceAll(" ", "_")}');
        } catch (e) {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                formatter.format(amount),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
