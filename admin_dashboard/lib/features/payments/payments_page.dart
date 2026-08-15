import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/models.dart';
import '../../providers/app_providers.dart';
import 'payment_providers.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  String _methodFilter = 'All';
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestorePaymentsAsync = ref.watch(firestorePaymentsProvider);
    final List<PaymentModel> rawPayments = firestorePaymentsAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : ref.watch(paymentsProvider),
      orElse: () => ref.watch(paymentsProvider),
    );

    // Calculate dynamic totals
    double totalCollected = 0.0;
    double cashTotal = 0.0;
    double cardTotal = 0.0;
    double qrTotal = 0.0;

    for (final p in rawPayments) {
      totalCollected += p.amount;
      final m = p.paymentMethod.toLowerCase();
      if (m.contains('cash')) {
        cashTotal += p.amount;
      } else if (m.contains('card')) {
        cardTotal += p.amount;
      } else {
        qrTotal += p.amount;
      }
    }

    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    // Filter payments
    final filteredPayments = rawPayments.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.transactionId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.paymentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.customerName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesMethod = _methodFilter == 'All' ||
          p.paymentMethod.toLowerCase().contains(_methodFilter.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
          p.paymentStatus.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesMethod && matchesStatus;
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
                  'Payments',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2332)),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _SummaryCard(title: 'Total Collected', value: formatCurrency.format(totalCollected), icon: Icons.payments, color: Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(title: 'Cash Total', value: formatCurrency.format(cashTotal), icon: Icons.money, color: Colors.teal)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(title: 'Card Total', value: formatCurrency.format(cardTotal), icon: Icons.credit_card, color: Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(title: 'QR / Online Total', value: formatCurrency.format(qrTotal), icon: Icons.qr_code_scanner, color: Colors.purple)),
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
                      hintText: 'Search Transaction ID, Order, Invoice, or Customer',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _methodFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['All', 'Cash', 'Card', 'UPI', 'QR']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _methodFilter = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['All', 'Paid', 'Completed', 'Pending', 'Refunded']
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
                      _methodFilter = 'All';
                      _statusFilter = 'All';
                    });
                  },
                  child: const Text('Clear'),
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
                child: _buildDataTable(filteredPayments),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<PaymentModel> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payments found'),
          ],
        ),
      );
    }
    return PaginatedDataTable2(
      minWidth: 1100,
      columns: const [
        DataColumn2(label: Text('Transaction ID'), size: ColumnSize.L),
        DataColumn2(label: Text('Invoice / Order Ref'), size: ColumnSize.M),
        DataColumn2(label: Text('Customer'), size: ColumnSize.L),
        DataColumn2(label: Text('Method'), size: ColumnSize.S),
        DataColumn2(label: Text('Amount'), size: ColumnSize.M, numeric: true),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text('Date / Time'), size: ColumnSize.M),
        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
      ],
      source: _PaymentsDataSource(context, payments),
      rowsPerPage: 10,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsDataSource extends DataTableSource {
  final BuildContext context;
  final List<PaymentModel> payments;

  _PaymentsDataSource(this.context, this.payments);

  @override
  DataRow? getRow(int index) {
    if (index >= payments.length) return null;
    final payment = payments[index];
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    final displayTxId = payment.transactionId.isNotEmpty
        ? payment.transactionId
        : (payment.paymentId.isNotEmpty ? payment.paymentId : payment.id);

    final displayOrderRef = payment.invoiceNumber.isNotEmpty
        ? payment.invoiceNumber
        : (payment.orderId.isNotEmpty ? payment.orderId : '-');

    return DataRow2(
      cells: [
        DataCell(Text(displayTxId, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          InkWell(
            onTap: payment.orderId.isNotEmpty ? () => context.go('/orders/${payment.orderId}') : null,
            child: Text(
              displayOrderRef,
              style: TextStyle(
                color: payment.orderId.isNotEmpty ? Colors.blue : Colors.black87,
                decoration: payment.orderId.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ),
        DataCell(Text(payment.customerName)),
        DataCell(_buildMethodBadge(payment.paymentMethod)),
        DataCell(Text(formatCurrency.format(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(_buildStatusBadge(payment.paymentStatus)),
        DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(payment.paymentDate))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Color(0xFF0F6D3B)),
              tooltip: 'Receipt Details',
              onPressed: () {
                _showReceiptModal(context, payment);
              },
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildMethodBadge(String method) {
    String displayMethod = method;
    if (displayMethod.startsWith('DocumentReference')) {
      displayMethod = 'Cash';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(displayMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == 'paid' || s == 'completed') color = Colors.green;
    if (s == 'pending') color = Colors.orange;
    if (s == 'refunded' || s == 'not refunded') color = s == 'refunded' ? Colors.red : Colors.blueGrey;
    if (s == 'failed') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showReceiptModal(BuildContext context, PaymentModel payment) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Color(0xFF0F6D3B)),
            const SizedBox(width: 8),
            Text('Receipt #${payment.invoiceNumber.isNotEmpty ? payment.invoiceNumber : payment.id}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Transaction ID', payment.transactionId.isNotEmpty ? payment.transactionId : payment.id),
              _detailRow('Order ID', payment.orderId.isNotEmpty ? payment.orderId : '-'),
              _detailRow('Customer', payment.customerName),
              _detailRow('Payment Method', payment.paymentMethod),
              _detailRow('Amount Paid', formatCurrency.format(payment.amount)),
              if (payment.refundAmount > 0) _detailRow('Refund Amount', formatCurrency.format(payment.refundAmount)),
              _detailRow('Status', payment.paymentStatus),
              _detailRow('Date', DateFormat('dd MMM yyyy, HH:mm:ss').format(payment.paymentDate)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    String cleanVal = value;
    if (cleanVal.startsWith('DocumentReference')) {
      if (cleanVal.contains('/')) {
        cleanVal = cleanVal.split('/').last.replaceAll(')', '').trim();
      } else {
        cleanVal = 'Cash';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              cleanVal,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => payments.length;
  @override
  int get selectedRowCount => 0;
}
