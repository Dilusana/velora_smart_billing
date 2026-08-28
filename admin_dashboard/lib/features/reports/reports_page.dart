import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../../providers/app_providers.dart';
import '../orders/order_providers.dart';
import '../customers/customer_providers.dart';
import '../inventory/inventory_providers.dart';
import '../products/product_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _selectedReportIndex = 0;
  int _selectedInventorySubTab = 0;
  int _selectedSalesSubTab = 0; // 0: All Sales, 1: Kiosk Orders, 2: App Orders
  
  // Date & Search Filters
  DateTimeRange? _selectedDateRange;
  String _salesSearchQuery = '';
  String _salesStatusFilter = 'All';
  final TextEditingController _salesSearchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2, locale: 'en_IN');

  final List<Map<String, dynamic>> _reports = [
    {'title': 'Sales Report (Kiosk & App)', 'icon': FontAwesomeIcons.chartLine},
    {'title': 'Inventory Report', 'icon': FontAwesomeIcons.boxesStacked},
    {'title': 'Customer Report', 'icon': FontAwesomeIcons.users},
  ];

  @override
  void dispose() {
    _salesSearchController.dispose();
    super.dispose();
  }

  Widget _buildReportContent(bool isDark) {
    switch (_selectedReportIndex) {
      case 0:
        return _buildSalesReport(isDark);
      case 1:
        return _buildInventoryReport(isDark);
      case 2:
        return _buildCustomerReport(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSalesReport(bool isDark) {
    final firestoreOrdersAsync = ref.watch(firestoreOrdersProvider);
    final fallbackOrders = ref.watch(ordersProvider);

    final List<OrderModel> orders = firestoreOrdersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : fallbackOrders,
      orElse: () => fallbackOrders,
    );

    // Map orders to sales representations with accurate source detection
    final List<SaleModel> allRawSales = orders.map((o) {
      final bLower = o.branch.toLowerCase();
      final delLower = o.deliveryType.toLowerCase();
      final isKiosk = bLower.contains('kiosk') || 
                      bLower.contains('pos') || 
                      bLower.contains('counter') || 
                      delLower.contains('kiosk') || 
                      delLower.contains('pos') || 
                      delLower.contains('dine');
      
      final source = isKiosk ? 'Kiosk' : 'App';
      final pStatus = o.paymentStatus.isNotEmpty 
          ? o.paymentStatus 
          : (o.paymentMethod.isNotEmpty ? 'paid' : 'pending');

      return SaleModel(
        id: o.id,
        orderId: o.id,
        invoiceNumber: o.id,
        customerId: o.customerId,
        customerName: o.customerName,
        orderSource: source,
        orderStatus: o.status,
        paymentStatus: pStatus,
        totalAmount: o.total,
        orderDate: o.createdAt,
      );
    }).toList();

    // Apply Filters
    final filteredSales = allRawSales.where((s) {
      // 1. Source Tab filter (0: All, 1: Kiosk, 2: App)
      if (_selectedSalesSubTab == 1 && s.orderSource.toLowerCase() != 'kiosk') return false;
      if (_selectedSalesSubTab == 2 && s.orderSource.toLowerCase() != 'app') return false;

      // 2. Search query filter
      final q = _salesSearchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchesQuery = s.id.toLowerCase().contains(q) ||
            s.orderId.toLowerCase().contains(q) ||
            s.invoiceNumber.toLowerCase().contains(q) ||
            s.customerName.toLowerCase().contains(q);
        if (!matchesQuery) return false;
      }

      // 3. Status filter
      if (_salesStatusFilter != 'All') {
        if (s.orderStatus.toLowerCase() != _salesStatusFilter.toLowerCase()) return false;
      }

      // 4. Date Range filter
      if (_selectedDateRange != null) {
        final date = s.orderDate;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      return true;
    }).toList();

    // Summary KPI Calculations
    double totalRevenue = 0;
    double kioskTotal = 0;
    double appTotal = 0;
    int kioskCount = 0;
    int appCount = 0;

    for (final s in allRawSales) {
      // Apply date filter to KPI cards if date filter is active
      if (_selectedDateRange != null) {
        final date = s.orderDate;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        if (date.isBefore(start) || date.isAfter(end)) continue;
      }

      totalRevenue += s.totalAmount;
      if (s.orderSource.toLowerCase().contains('app')) {
        appTotal += s.totalAmount;
        appCount++;
      } else {
        kioskTotal += s.totalAmount;
        kioskCount++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on_outlined, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Total Sales Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currencyFormat.format(totalRevenue), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text('${kioskCount + appCount} Total Orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Card(
                color: Colors.blue.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.point_of_sale, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Kiosk Orders Sales', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currencyFormat.format(kioskTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text('$kioskCount Transactions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Card(
                color: Colors.purple.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.purple.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('App Orders Sales', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currencyFormat.format(appTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                      const SizedBox(height: 4),
                      Text('$appCount Mobile Orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tabs (All Sales / Kiosk Orders / App Orders) & Filter Toolbar
        Row(
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.receipt_long, size: 16),
              label: const Text('All Sales History'),
              selected: _selectedSalesSubTab == 0,
              onSelected: (selected) {
                if (selected) setState(() => _selectedSalesSubTab = 0);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedSalesSubTab == 0 ? AppColors.primary : null,
                fontWeight: _selectedSalesSubTab == 0 ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: const Icon(Icons.point_of_sale, size: 16),
              label: const Text('Kiosk Orders'),
              selected: _selectedSalesSubTab == 1,
              onSelected: (selected) {
                if (selected) setState(() => _selectedSalesSubTab = 1);
              },
              selectedColor: Colors.blue.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedSalesSubTab == 1 ? Colors.blue : null,
                fontWeight: _selectedSalesSubTab == 1 ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: const Icon(Icons.phone_android, size: 16),
              label: const Text('App Orders'),
              selected: _selectedSalesSubTab == 2,
              onSelected: (selected) {
                if (selected) setState(() => _selectedSalesSubTab = 2);
              },
              selectedColor: Colors.purple.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedSalesSubTab == 2 ? Colors.purple : null,
                fontWeight: _selectedSalesSubTab == 2 ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search, Status Filter & Date Picker Toolbar
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _salesSearchController,
                onChanged: (val) => setState(() => _salesSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search Order #, Invoice, or Customer...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _salesStatusFilter,
                decoration: InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['All', 'Completed', 'Processing', 'Pending', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) => setState(() => _salesStatusFilter = val!),
              ),
            ),
            const SizedBox(width: 10),
            // Date Filter Button
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(
                  color: _selectedDateRange != null ? AppColors.primary : Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.calendar_today,
                size: 16,
                color: _selectedDateRange != null ? AppColors.primary : Colors.grey.shade700,
              ),
              label: Text(
                _selectedDateRange == null
                    ? 'Filter Date'
                    : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDateRange != null ? AppColors.primary : null,
                  fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (_selectedDateRange != null || _salesSearchQuery.isNotEmpty || _salesStatusFilter != 'All') ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Reset Filters',
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;
                    _salesSearchQuery = '';
                    _salesSearchController.clear();
                    _salesStatusFilter = 'All';
                  });
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Sales Table
        Expanded(
          child: filteredSales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No sales records match your filters.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      if (_selectedDateRange != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedDateRange = null),
                          child: const Text('Clear Date Range'),
                        ),
                    ],
                  ),
                )
              : DataTable2(
                  minWidth: 1000,
                  columns: const [
                    DataColumn2(label: Text('Invoice / Order Ref'), fixedWidth: 150),
                    DataColumn2(label: Text('Customer'), size: ColumnSize.L),
                    DataColumn2(label: Text('Source / Channel'), fixedWidth: 140),
                    DataColumn2(label: Text('Date & Time'), fixedWidth: 170),
                    DataColumn2(label: Text('Amount'), fixedWidth: 130, numeric: true),
                    DataColumn2(label: Text('Payment'), fixedWidth: 110),
                    DataColumn2(label: Text('Order Status'), fixedWidth: 130),
                  ],
                  rows: filteredSales.map((sale) {
                    final isKiosk = !sale.orderSource.toLowerCase().contains('app');
                    return DataRow(cells: [
                      DataCell(Text(sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(sale.customerName)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isKiosk ? Colors.blue.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isKiosk ? Icons.point_of_sale : Icons.phone_android, size: 12, color: isKiosk ? Colors.blue : Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                sale.orderSource,
                                style: TextStyle(color: isKiosk ? Colors.blue : Colors.purple, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(sale.orderDate))),
                      DataCell(Text(_currencyFormat.format(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sale.paymentStatus.toLowerCase() == 'paid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sale.paymentStatus.toUpperCase(),
                            style: TextStyle(
                              color: sale.paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sale.orderStatus.toLowerCase() == 'completed'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sale.orderStatus,
                            style: TextStyle(
                              color: sale.orderStatus.toLowerCase() == 'completed' ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryReport(bool isDark) {
    final inventory = ref.watch(inventoryProvider);
    final firestoreProductsAsync = ref.watch(firestoreProductsProvider);
    final adjustmentsAsync = ref.watch(allStockAdjustmentsProvider);

    final List<StockAdjustmentModel> adjustments = adjustmentsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    int totalAdded = 0;
    int totalRemoved = 0;
    for (final adj in adjustments) {
      if (adj.type.toLowerCase() == 'add') {
        totalAdded += adj.quantity;
      } else {
        totalRemoved += adj.quantity;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.inventory_2_outlined, size: 16),
              label: const Text('Stock & Value'),
              selected: _selectedInventorySubTab == 0,
              onSelected: (selected) {
                if (selected) setState(() => _selectedInventorySubTab = 0);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedInventorySubTab == 0 ? AppColors.primary : null,
                fontWeight: _selectedInventorySubTab == 0 ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              avatar: const Icon(Icons.tune, size: 16),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Stock Adjustments Log'),
                  if (adjustments.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${adjustments.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              selected: _selectedInventorySubTab == 1,
              onSelected: (selected) {
                if (selected) setState(() => _selectedInventorySubTab = 1);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedInventorySubTab == 1 ? AppColors.primary : null,
                fontWeight: _selectedInventorySubTab == 1 ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedInventorySubTab == 0) ...[
          const Text('Inventory Stock & Value Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: firestoreProductsAsync.maybeWhen(
              data: (products) => products.isNotEmpty
                  ? DataTable2(
                      columns: const [
                        DataColumn2(label: Text('Product Name')),
                        DataColumn2(label: Text('SKU')),
                        DataColumn2(label: Text('Category')),
                        DataColumn2(label: Text('Current Stock'), numeric: true),
                        DataColumn2(label: Text('Unit Price'), numeric: true),
                        DataColumn2(label: Text('Status')),
                      ],
                      rows: products.map((item) {
                        final isLowStock = item.stock <= 10;
                        return DataRow(cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item.sku)),
                          DataCell(Text(item.category)),
                          DataCell(Text('${item.stock} ${item.unit}')),
                          DataCell(Text(_currencyFormat.format(item.price))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLowStock ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isLowStock ? 'LOW STOCK' : 'IN STOCK',
                                style: TextStyle(
                                  color: isLowStock ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    )
                  : _buildFallbackInventoryTable(inventory),
              orElse: () => _buildFallbackInventoryTable(inventory),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.withValues(alpha: 0.08),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Total Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${adjustments.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.green.withValues(alpha: 0.08),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Stock Added', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('+$totalAdded units', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.red.withValues(alpha: 0.08),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Stock Removed', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('-$totalRemoved units', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Stock Adjustments History & Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: adjustmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading stock adjustments: $err')),
              data: (adjList) {
                if (adjList.isEmpty) {
                  return const Center(child: Text('No stock adjustments recorded.'));
                }
                return DataTable2(
                  columns: const [
                    DataColumn2(label: Text('Product Name')),
                    DataColumn2(label: Text('Type')),
                    DataColumn2(label: Text('Quantity'), numeric: true),
                    DataColumn2(label: Text('Reason')),
                    DataColumn2(label: Text('Notes')),
                    DataColumn2(label: Text('Adjusted By')),
                    DataColumn2(label: Text('Date & Time')),
                  ],
                  rows: adjList.map((adj) {
                    final isAdd = adj.type.toLowerCase() == 'add';
                    return DataRow(cells: [
                      DataCell(Text(adj.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdd ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adj.type.toUpperCase(),
                            style: TextStyle(
                              color: isAdd ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(
                        isAdd ? '+${adj.quantity}' : '-${adj.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAdd ? Colors.green : Colors.red,
                        ),
                      )),
                      DataCell(Text(adj.reason)),
                      DataCell(Text(adj.notes.isNotEmpty ? adj.notes : '—')),
                      DataCell(Text(adj.adjustedBy.isNotEmpty ? adj.adjustedBy : 'Admin User')),
                      DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(adj.createdAt))),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackInventoryTable(List<InventoryItemModel> inventory) {
    return DataTable2(
      columns: const [
        DataColumn2(label: Text('Product Name')),
        DataColumn2(label: Text('Current Stock'), numeric: true),
        DataColumn2(label: Text('Reorder Level'), numeric: true),
        DataColumn2(label: Text('Warehouse')),
        DataColumn2(label: Text('Status')),
      ],
      rows: inventory.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('${item.currentStock}')),
          DataCell(Text('${item.reorderLevel}')),
          DataCell(Text(item.warehouse)),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.currentStock <= item.reorderLevel
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.currentStock <= item.reorderLevel ? 'LOW STOCK' : 'IN STOCK',
                style: TextStyle(
                  color: item.currentStock <= item.reorderLevel ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildCustomerReport(bool isDark) {
    final firestoreCustomersAsync = ref.watch(firestoreCustomersProvider);
    final List<CustomerModel> customers = firestoreCustomersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : ref.watch(customersProvider),
      orElse: () => ref.watch(customersProvider),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Activity & Loyalty Tier Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: DataTable2(
            columns: const [
              DataColumn2(label: Text('Customer Name')),
              DataColumn2(label: Text('Email')),
              DataColumn2(label: Text('Phone')),
              DataColumn2(label: Text('Tier')),
              DataColumn2(label: Text('Loyalty Points'), numeric: true),
              DataColumn2(label: Text('Total Spend'), numeric: true),
            ],
            rows: customers.map((c) {
              return DataRow(cells: [
                DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(c.email)),
                DataCell(Text(c.phone)),
                DataCell(Text(c.loyaltyTier)),
                DataCell(Text('${c.loyaltyPoints}')),
                DataCell(Text(_currencyFormat.format(c.totalSpend))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Generates and previews / exports PDF for Sales, Inventory, or Customers
  Future<void> _exportPdfReport() async {
    final pdf = pw.Document();

    final firestoreOrdersAsync = ref.read(firestoreOrdersProvider);
    final fallbackOrders = ref.read(ordersProvider);

    final List<OrderModel> orders = firestoreOrdersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : fallbackOrders,
      orElse: () => fallbackOrders,
    );

    final List<SaleModel> allRawSales = orders.map((o) {
      final bLower = o.branch.toLowerCase();
      final delLower = o.deliveryType.toLowerCase();
      final isKiosk = bLower.contains('kiosk') || 
                      bLower.contains('pos') || 
                      bLower.contains('counter') || 
                      delLower.contains('kiosk') || 
                      delLower.contains('pos') || 
                      delLower.contains('dine');
      
      final source = isKiosk ? 'Kiosk' : 'App';
      final pStatus = o.paymentStatus.isNotEmpty 
          ? o.paymentStatus 
          : (o.paymentMethod.isNotEmpty ? 'paid' : 'pending');

      return SaleModel(
        id: o.id,
        orderId: o.id,
        invoiceNumber: o.id,
        customerId: o.customerId,
        customerName: o.customerName,
        orderSource: source,
        orderStatus: o.status,
        paymentStatus: pStatus,
        totalAmount: o.total,
        orderDate: o.createdAt,
      );
    }).toList();

    // Apply active filter
    final filteredSales = allRawSales.where((s) {
      if (_selectedSalesSubTab == 1 && s.orderSource.toLowerCase() != 'kiosk') return false;
      if (_selectedSalesSubTab == 2 && s.orderSource.toLowerCase() != 'app') return false;
      final q = _salesSearchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchesQuery = s.id.toLowerCase().contains(q) ||
            s.orderId.toLowerCase().contains(q) ||
            s.invoiceNumber.toLowerCase().contains(q) ||
            s.customerName.toLowerCase().contains(q);
        if (!matchesQuery) return false;
      }
      if (_salesStatusFilter != 'All') {
        if (s.orderStatus.toLowerCase() != _salesStatusFilter.toLowerCase()) return false;
      }
      if (_selectedDateRange != null) {
        final date = s.orderDate;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    double totalAmount = filteredSales.fold(0.0, (acc, item) => acc + item.totalAmount);
    final dateRangeStr = _selectedDateRange != null
        ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} to ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
        : 'All Time';

    final categoryLabel = _selectedSalesSubTab == 1
        ? 'Kiosk Orders Report'
        : (_selectedSalesSubTab == 2 ? 'App Orders Report' : 'Consolidated Sales Report');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VELORA RETAIL & BILLING', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.SizedBox(height: 2),
                    pw.Text(categoryLabel, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date Scope: $dateRangeStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Total Records: ${filteredSales.length}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('Total: Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.teal800),
            pw.SizedBox(height: 12),

            // Table of Sales
            pw.TableHelper.fromTextArray(
              headers: ['Invoice #', 'Customer', 'Channel', 'Date', 'Amount (Rs.)', 'Status'],
              data: filteredSales.map((s) => [
                s.invoiceNumber.isNotEmpty ? s.invoiceNumber : s.id,
                s.customerName,
                s.orderSource,
                DateFormat('dd MMM yyyy, HH:mm').format(s.orderDate),
                s.totalAmount.toStringAsFixed(2),
                s.orderStatus,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
            ),
            pw.SizedBox(height: 16),

            // Summary Footer
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Grand Total: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Velora_${categoryLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 260,
            color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedReportIndex == index;
                return ListTile(
                  leading: Icon(_reports[index]['icon'], color: isSelected ? AppColors.primary : AppColors.textMuted),
                  title: Text(
                    _reports[index]['title'],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () => setState(() => _selectedReportIndex = index),
                );
              },
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _exportPdfReport,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.table_chart, size: 18),
                        label: const Text('Export CSV'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exporting Report CSV...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildReportContent(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
