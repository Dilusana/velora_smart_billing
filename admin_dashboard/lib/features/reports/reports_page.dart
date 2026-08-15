import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../../providers/app_providers.dart';
import '../sales/sale_providers.dart';
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
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2, locale: 'en_IN');

  final List<Map<String, dynamic>> _reports = [
    {'title': 'Sales Report (Kiosk & App)', 'icon': FontAwesomeIcons.chartLine},
    {'title': 'Inventory Report', 'icon': FontAwesomeIcons.boxesStacked},
    {'title': 'Order Report', 'icon': FontAwesomeIcons.receipt},
    {'title': 'Customer Report', 'icon': FontAwesomeIcons.users},
  ];

  Widget _buildReportContent(bool isDark) {
    switch (_selectedReportIndex) {
      case 0:
        return _buildSalesReport(isDark);
      case 1:
        return _buildInventoryReport(isDark);
      case 2:
        return _buildOrderReport(isDark);
      case 3:
        return _buildCustomerReport(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSalesReport(bool isDark) {
    final firestoreSalesAsync = ref.watch(firestoreSalesProvider);
    final orders = ref.watch(ordersProvider);

    final List<SaleModel> sales = firestoreSalesAsync.maybeWhen(
      data: (list) => list.isNotEmpty
          ? list
          : orders
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

    double kioskTotal = 0;
    double appTotal = 0;
    for (final s in sales) {
      if (s.orderSource.toLowerCase().contains('app')) {
        appTotal += s.totalAmount;
      } else {
        kioskTotal += s.totalAmount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          Icon(Icons.point_of_sale, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Kiosk Sales Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currencyFormat.format(kioskTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Colors.purple.withValues(alpha: 0.08),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('App Sales Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currencyFormat.format(appTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Recent Kiosk & App Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: DataTable2(
            columns: const [
              DataColumn2(label: Text('Invoice / Order Ref')),
              DataColumn2(label: Text('Customer')),
              DataColumn2(label: Text('Source')),
              DataColumn2(label: Text('Date / Time')),
              DataColumn2(label: Text('Amount'), numeric: true),
              DataColumn2(label: Text('Status')),
            ],
            rows: sales.map((sale) {
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
                    child: Text(
                      sale.orderSource,
                      style: TextStyle(color: isKiosk ? Colors.blue : Colors.purple, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
                DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(sale.orderDate))),
                DataCell(Text(_currencyFormat.format(sale.totalAmount))),
                DataCell(Text(sale.orderStatus)),
              ]);
            }).toList(),
          ),
        )
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

  Widget _buildOrderReport(bool isDark) {
    final firestoreOrdersAsync = ref.watch(firestoreOrdersProvider);
    final List<OrderModel> orders = firestoreOrdersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : ref.watch(ordersProvider),
      orElse: () => ref.watch(ordersProvider),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Orders Status & Breakdown Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: DataTable2(
            columns: const [
              DataColumn2(label: Text('Order ID')),
              DataColumn2(label: Text('Customer')),
              DataColumn2(label: Text('Branch')),
              DataColumn2(label: Text('Date')),
              DataColumn2(label: Text('Total'), numeric: true),
              DataColumn2(label: Text('Status')),
            ],
            rows: orders.map((order) {
              return DataRow(cells: [
                DataCell(Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(order.customerName)),
                DataCell(Text(order.branch)),
                DataCell(Text(DateFormat('dd MMM yyyy').format(order.createdAt))),
                DataCell(Text(_currencyFormat.format(order.total))),
                DataCell(Text(order.status)),
              ]);
            }).toList(),
          ),
        ),
      ],
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
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export CSV'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
