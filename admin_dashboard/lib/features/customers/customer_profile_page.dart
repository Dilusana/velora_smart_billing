import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/models.dart';
import '../../core/theme/app_theme.dart';
import '../orders/order_providers.dart';
import 'customer_providers.dart';

class CustomerProfilePage extends ConsumerWidget {
  final String customerId;

  const CustomerProfilePage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(firestoreCustomersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return customersAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/customers'),
          ),
          title: const Text('Error'),
        ),
        body: Center(child: Text('Error loading customer: $e')),
      ),
      data: (customers) {
        final customer = customers.cast<CustomerModel?>().firstWhere(
          (c) => c?.id == customerId,
          orElse: () => null,
        );

        if (customer == null) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/customers'),
              ),
              title: const Text('Customer Not Found'),
            ),
            body: const Center(child: Text('Customer not found.')),
          );
        }

        final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
        final initials = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';
        final avgOrderValue = customer.totalOrders > 0
            ? customer.totalSpend / customer.totalOrders
            : 0.0;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/customers'),
            ),
            title: Text(customer.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // ── Profile Header Card ──────────────────────────────────────
                Card(
                  color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${customer.email.isNotEmpty ? customer.email : 'No email'} | ${customer.phone.isNotEmpty ? customer.phone : 'No phone'}',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                              if (customer.address.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(customer.address, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('${customer.loyaltyTier} Tier',
                                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (customer.status.toLowerCase() == 'active' ? AppColors.statusGreen : Colors.grey)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      customer.status,
                                      style: TextStyle(
                                        color: customer.status.toLowerCase() == 'active' ? AppColors.statusGreen : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Summary Stats ─────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Total Orders', value: '${customer.totalOrders}', isDark: isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(title: 'Total Spend', value: formatCurrency.format(customer.totalSpend), isDark: isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(title: 'Loyalty Points', value: '${customer.loyaltyPoints}', isDark: isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(title: 'Avg Order Value', value: formatCurrency.format(avgOrderValue), isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Order History Section ─────────────────────────────────────
                _CustomerOrdersTab(customer: customer, isDark: isDark),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  const _StatCard({required this.title, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CustomerOrdersTab extends ConsumerWidget {
  final CustomerModel customer;
  final bool isDark;
  const _CustomerOrdersTab({required this.customer, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(firestoreOrdersProvider);
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    return Card(
      color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading orders: $err'),
              data: (allOrders) {
                final customerOrders = allOrders.where((o) =>
                    o.customerId == customer.id ||
                    (o.customerName.isNotEmpty &&
                        o.customerName.toLowerCase() == customer.name.toLowerCase())).toList();

                if (customerOrders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('No orders found for this customer.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customerOrders.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.bgDarkBorder : AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final order = customerOrders[index];
                    return ListTile(
                      title: Text(
                        'Order #${order.id.toUpperCase().substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)} · ${order.items.length} item(s)',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatCurrency.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(color: AppColors.statusGreen, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => context.go('/orders/${order.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

