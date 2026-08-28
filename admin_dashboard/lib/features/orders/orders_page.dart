import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../core/data/models.dart';
import 'new_order_dialog.dart';
import 'order_providers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _paymentFilter = 'All';
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF0F6D3B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  bool _matchesDateRange(DateTime orderDate) {
    if (_selectedDateRange == null) return true;
    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
      0,
      0,
      0,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
    );
    return orderDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
        orderDate.isBefore(end.add(const Duration(seconds: 1)));
  }

  String _getDateFilterLabel() {
    if (_selectedDateRange == null) return 'Filter by Date';
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreOrdersAsync = ref.watch(firestoreOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // bgPrimary
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 24),
            _buildFilterBar(),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: firestoreOrdersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading orders: $err')),
                  data: (rawOrders) {
                    final filteredOrders = rawOrders.where((order) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase());

                      final matchesStatus = _statusFilter == 'All' ||
                          order.status.toLowerCase() == _statusFilter.toLowerCase();

                      final matchesPayment = _paymentFilter == 'All' ||
                          order.paymentMethod.toLowerCase().contains(_paymentFilter.toLowerCase()) ||
                          order.paymentStatus.toLowerCase().contains(_paymentFilter.toLowerCase());

                      final matchesDate = _matchesDateRange(order.createdAt);

                      return matchesSearch && matchesStatus && matchesPayment && matchesDate;
                    }).toList();

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const NewOrderDialog(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F6D3B),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Order'),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildDataTable(filteredOrders);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sales',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2332)),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const NewOrderDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6D3B),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Order ID or Customer',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _statusFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: ['All', 'Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled']
                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => _statusFilter = val!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _paymentFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: ['All', 'Cash', 'Card', 'QR']
                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => _paymentFilter = val!),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => _pickDateRange(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: _selectedDateRange != null ? const Color(0xFF0F6D3B) : null,
            side: BorderSide(
              color: _selectedDateRange != null ? const Color(0xFF0F6D3B) : Colors.grey.shade400,
            ),
          ),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(_getDateFilterLabel()),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _statusFilter = 'All';
              _paymentFilter = 'All';
              _selectedDateRange = null;
            });
          },
          child: const Text('Clear Filters'),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders found'),
          ],
        ),
      );
    }
    return PaginatedDataTable2(
      minWidth: 1200,
      dataRowHeight: 72,
      headingRowHeight: 56,
      columns: const [
        DataColumn2(label: Text('Order ID'), size: ColumnSize.M),
        DataColumn2(label: Text('Customer'), size: ColumnSize.L),
        DataColumn2(label: Text('Date/Time'), size: ColumnSize.L),
        DataColumn2(label: Text('Items'), size: ColumnSize.S),
        DataColumn2(label: Text('Total (Rs.)'), size: ColumnSize.M, numeric: true),
        DataColumn2(label: Text('Payment Method'), size: ColumnSize.L),
        DataColumn2(label: Text('Status'), size: ColumnSize.M),
        DataColumn2(label: Text('Employee'), size: ColumnSize.M),
        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
      ],
      source: _OrdersDataSource(context, orders),
      rowsPerPage: 10,
    );
  }
}

class _OrdersDataSource extends DataTableSource {
  final BuildContext context;
  final List<OrderModel> orders;

  _OrdersDataSource(this.context, this.orders);

  @override
  DataRow? getRow(int index) {
    if (index >= orders.length) return null;
    final order = orders[index];
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    return DataRow2(
      onSelectChanged: (_) {
        context.go('/orders/${order.id}');
      },
      cells: [
        DataCell(Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Row(
          children: [
            CircleAvatar(radius: 12, child: Text(order.customerName.isNotEmpty ? order.customerName[0] : '?')),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.customerName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        )),
        DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt))),
        DataCell(Text('${order.items.length}')),
        DataCell(Text(formatCurrency.format(order.total))),
        DataCell(_buildBadge(order.paymentMethod)),
        DataCell(_buildStatusBadge(order.status)),
        DataCell(Text(order.branch)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => context.go('/orders/${order.id}'),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.teal, fontSize: 12)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    final lower = status.toLowerCase().trim();
    if (lower == 'pending') color = Colors.amber;
    if (lower == 'processing') color = Colors.blue;
    if (lower == 'shipped') color = Colors.purple;
    if (lower == 'completed') color = Colors.green;
    if (lower == 'cancelled' || lower == 'canceled') color = Colors.red;

    final displayLabel = status.isEmpty ? 'Pending' : (status[0].toUpperCase() + status.substring(1).toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(displayLabel, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => orders.length;
  @override
  int get selectedRowCount => 0;
}
