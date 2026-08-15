import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../inventory/inventory_providers.dart';
import '../inventory/inventory_repository.dart';
import 'order_providers.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  String? _selectedStatus;
  bool _updatingStatus = false;

  String _normalizeStatus(String rawStatus) {
    if (rawStatus.isEmpty) return 'Pending';
    final lower = rawStatus.toLowerCase().trim();
    switch (lower) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final formatCurrency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    return orderAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error loading order: $e'))),
      data: (order) {
        if (order == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Order not found',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => context.go('/orders'),
                    child: const Text('Back to Orders')),
              ]),
            ),
          );
        }

        _selectedStatus ??= _normalizeStatus(order.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/orders'),
            ),
            title: Text('Order #${order.id.toUpperCase().substring(0, 8)}'),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _printInvoice(context, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6D3B),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.print),
                  label: const Text('Print Invoice'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildOrderInfoCard(order, formatCurrency)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCustomerInfoCard(order)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildOrderItemsCard(order, formatCurrency),
                          const SizedBox(height: 24),
                          _buildStatusStepper(order.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildOrderSummaryCard(order, formatCurrency),
                          const SizedBox(height: 24),
                          _buildUpdateStatusCard(order),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderInfoCard(OrderModel order, NumberFormat fmt) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Order ID: #${order.id.toUpperCase().substring(0, 8)}'),
            Text('Date: ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)}'),
            Text('Employee: ${order.branch}'),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(order.paymentMethod,
                  style: const TextStyle(color: Colors.teal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(OrderModel order) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Name: ${order.customerName}'),
            Text('Customer ID: ${order.customerId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(OrderModel order, NumberFormat formatter) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                const TableRow(
                  children: [
                    Text('Product',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Qty',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Unit Price',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                ...order.items.map((item) => TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(item.productName)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${item.quantity}')),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(formatter.format(item.unitPrice))),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(formatter.format(item.total))),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderModel order, NumberFormat formatter) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text(formatter.format(order.total)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(formatter.format(order.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStepper(String currentStatus) {
    const steps = ['Pending', 'Processing', 'Shipped', 'Completed'];
    final normalized = _normalizeStatus(currentStatus);
    final currentIndex = steps.indexOf(normalized);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((e) {
            final isActive = e.key <= currentIndex;
            final isCurrent = e.key == currentIndex;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.green
                            : isActive
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (e.key < steps.length - 1)
                    const Icon(Icons.arrow_forward,
                        color: Colors.grey, size: 16),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUpdateStatusCard(OrderModel order) {
    const statuses = [
      'Pending',
      'Processing',
      'Shipped',
      'Completed',
      'Cancelled'
    ];
    final currentNorm = _normalizeStatus(order.status);
    final selectedNorm = _normalizeStatus(_selectedStatus ?? order.status);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: statuses.contains(selectedNorm) ? selectedNorm : 'Pending',
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
              items: statuses
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: currentNorm == 'Cancelled' ||
                      currentNorm == 'Completed'
                  ? null // Lock dropdown if already terminal
                  : (val) => setState(() => _selectedStatus = val),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6D3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _updatingStatus ||
                        selectedNorm == currentNorm ||
                        currentNorm == 'Cancelled' ||
                        currentNorm == 'Completed'
                    ? null
                    : () => _updateStatus(order),
                child: _updatingStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Update Status'),
              ),
            ),
            if (currentNorm == 'Completed')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Stock deducted & COGS recorded',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status update logic — triggers FIFO deduction on Completed
  // ---------------------------------------------------------------------------

  Future<void> _updateStatus(OrderModel order) async {
    if (_selectedStatus == null) return;
    setState(() => _updatingStatus = true);

    try {
      final orderRepo = ref.read(orderRepositoryProvider);

      // 1. Update order status in Firestore
      await orderRepo.updateOrderStatus(order.id, _selectedStatus!);

      // 2. If transitioning to Completed, run FIFO deduction for each product
      if (_selectedStatus == 'Completed') {
        final inventoryRepo = ref.read(inventoryRepositoryProvider);
        try {
          await inventoryRepo.processFifoSaleForOrder(order);
        } on InsufficientStockException catch (e) {
          if (!mounted) return;
          _showErrorSnackbar(
            'Stock deduction failed for product ${e.productId}: '
            'requested ${e.requested} but only ${e.available} available. '
            'Stock was NOT deducted. Please adjust stock before completing.',
          );
          // Revert order status back to previous
          await orderRepo.updateOrderStatus(order.id, order.status);
          setState(() => _updatingStatus = false);
          return;
        }
      }

      if (!mounted) return;
      _showSuccessSnackbar(
        _selectedStatus == 'Completed'
            ? 'Order completed — Stock deducted & COGS recorded'
            : 'Order status updated to $_selectedStatus',
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to update status: $e');
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _printInvoice(BuildContext context, OrderModel order) async {
    final formatCurrency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice',
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Order #${order.id.toUpperCase().substring(0, 8)}'),
              pw.Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}'),
              pw.Text('Customer: ${order.customerName}'),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Product', 'Qty', 'Unit Price', 'Total'],
                data: order.items
                    .map((item) => [
                          item.productName,
                          '${item.quantity}',
                          formatCurrency.format(item.unitPrice),
                          formatCurrency.format(item.total),
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Grand Total: ${formatCurrency.format(order.total)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
