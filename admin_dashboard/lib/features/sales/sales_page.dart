import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

import '../../core/data/models.dart';
import '../../providers/app_providers.dart';
import 'sale_providers.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  String _searchQuery = '';
  String _sourceFilter = 'All';
  String _statusFilter = 'All';
  String _paymentFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreSalesAsync = ref.watch(firestoreSalesProvider);
    final orders = ref.watch(ordersProvider);

    final List<SaleModel> rawSales = firestoreSalesAsync.maybeWhen(
      data: (list) => list.isNotEmpty
          ? list
          : orders
              .map((o) => SaleModel(
                    id: o.id,
                    orderId: o.id,
                    invoiceNumber: o.id,
                    customerId: o.customerId,
                    customerName: o.customerName,
                    orderSource: o.branch.toLowerCase().contains('kiosk') ? 'Kiosk' : 'App',
                    orderStatus: o.status,
                    paymentStatus: o.paymentMethod.isNotEmpty ? 'paid' : 'pending',
                    totalAmount: o.total,
                    orderDate: o.createdAt,
                  ))
              .toList(),
      orElse: () => orders
          .map((o) => SaleModel(
                id: o.id,
                orderId: o.id,
                invoiceNumber: o.id,
                customerId: o.customerId,
                customerName: o.customerName,
                orderSource: 'Kiosk',
                orderStatus: o.status,
                paymentStatus: 'paid',
                totalAmount: o.total,
                orderDate: o.createdAt,
              ))
          .toList(),
    );

    // Dynamic metrics
    double totalRevenue = 0.0;
    double kioskRevenue = 0.0;
    double appRevenue = 0.0;
    int kioskCount = 0;
    int appCount = 0;

    for (final s in rawSales) {
      totalRevenue += s.totalAmount;
      final src = s.orderSource.toLowerCase();
      if (src.contains('app')) {
        appRevenue += s.totalAmount;
        appCount++;
      } else {
        kioskRevenue += s.totalAmount;
        kioskCount++;
      }
    }

    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    // Filter sales
    final filteredSales = rawSales.where((sale) {
      final matchesSearch = _searchQuery.isEmpty ||
          sale.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale.customerName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSource = _sourceFilter == 'All' ||
          sale.orderSource.toLowerCase() == _sourceFilter.toLowerCase();

      final matchesStatus = _statusFilter == 'All' ||
          sale.orderStatus.toLowerCase() == _statusFilter.toLowerCase();

      final matchesPayment = _paymentFilter == 'All' ||
          sale.paymentStatus.toLowerCase() == _paymentFilter.toLowerCase();

      return matchesSearch && matchesSource && matchesStatus && matchesPayment;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales History (Kiosk & App)',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2332)),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _SummaryCard(title: 'Total Revenue', value: formatCurrency.format(totalRevenue), subtitle: '${rawSales.length} Total Sales', icon: Icons.attach_money, color: Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(title: 'Kiosk System Sales', value: formatCurrency.format(kioskRevenue), subtitle: '$kioskCount Transactions', icon: Icons.point_of_sale, color: Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(title: 'App Sales', value: formatCurrency.format(appRevenue), subtitle: '$appCount Mobile Orders', icon: Icons.phone_android, color: Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search Order ID, Invoice Number, or Customer',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sourceFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['All', 'Kiosk', 'App', 'Web']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _sourceFilter = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['All', 'Completed', 'Pending', 'Processing', 'Cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _statusFilter = val!),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _sourceFilter = 'All';
                      _statusFilter = 'All';
                      _paymentFilter = 'All';
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: _buildDataTable(filteredSales),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<SaleModel> sales) {
    if (sales.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sales records found'),
          ],
        ),
      );
    }
    return PaginatedDataTable2(
      minWidth: 1100,
      columns: const [
        DataColumn2(label: Text('Invoice / Order ID'), size: ColumnSize.L),
        DataColumn2(label: Text('Customer'), size: ColumnSize.L),
        DataColumn2(label: Text('Source'), size: ColumnSize.M),
        DataColumn2(label: Text('Order Date'), size: ColumnSize.L),
        DataColumn2(label: Text('Amount'), size: ColumnSize.M, numeric: true),
        DataColumn2(label: Text('Payment Status'), size: ColumnSize.M),
        DataColumn2(label: Text('Order Status'), size: ColumnSize.M),
        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
      ],
      source: _SalesDataSource(context, sales),
      rowsPerPage: 10,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesDataSource extends DataTableSource {
  final BuildContext context;
  final List<SaleModel> sales;

  _SalesDataSource(this.context, this.sales);

  @override
  DataRow? getRow(int index) {
    if (index >= sales.length) return null;
    final sale = sales[index];
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    final displayRef = sale.invoiceNumber.isNotEmpty
        ? sale.invoiceNumber
        : (sale.orderId.isNotEmpty ? sale.orderId : sale.id);

    return DataRow2(
      onSelectChanged: (_) {
        if (sale.orderId.isNotEmpty) {
          context.go('/orders/${sale.orderId}');
        }
      },
      cells: [
        DataCell(Text(displayRef, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(sale.customerName)),
        DataCell(_buildSourceBadge(sale.orderSource)),
        DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(sale.orderDate))),
        DataCell(Text(formatCurrency.format(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(_buildPaymentBadge(sale.paymentStatus)),
        DataCell(_buildStatusBadge(sale.orderStatus)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                if (sale.orderId.isNotEmpty) {
                  context.go('/orders/${sale.orderId}');
                }
              },
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color = Colors.blue;
    IconData icon = Icons.point_of_sale;
    final s = source.toLowerCase();
    if (s.contains('app') || s.contains('mobile')) {
      color = Colors.purple;
      icon = Icons.phone_android;
    } else if (s.contains('web')) {
      color = Colors.teal;
      icon = Icons.web;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(source, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color = Colors.green;
    final s = status.toLowerCase();
    if (s == 'unpaid' || s == 'pending') color = Colors.orange;
    if (s == 'refunded') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == 'completed') color = Colors.green;
    if (s == 'processing' || s == 'pending') color = Colors.blue;
    if (s == 'cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => sales.length;
  @override
  int get selectedRowCount => 0;
}
