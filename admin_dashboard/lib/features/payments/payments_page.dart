import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/models.dart';
import '../../core/theme/app_theme.dart';
import '../suppliers/supplier_providers.dart';
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
  DateTimeRange? _selectedDateRange;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestorePaymentsAsync = ref.watch(firestorePaymentsProvider);

    final List<PaymentModel> rawPayments = firestorePaymentsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Dynamic metrics
    double totalAmount = 0.0;
    double paidTotal = 0.0;
    double pendingTotal = 0.0;
    double scheduledTotal = 0.0;
    int pendingCount = 0;
    int scheduledCount = 0;
    int overdueCount = 0;

    for (final p in rawPayments) {
      totalAmount += p.amount;
      final st = p.paymentStatus.toLowerCase();

      final schDate = p.scheduledPaymentDate;
      final isOverdue = st.contains('overdue') ||
          (st.contains('pending') && schDate != null && schDate.isBefore(todayDate));

      if (st.contains('paid') || st.contains('completed')) {
        paidTotal += p.amount;
      } else if (isOverdue) {
        pendingTotal += p.amount;
        overdueCount++;
      } else if (st.contains('scheduled')) {
        scheduledTotal += p.amount;
        scheduledCount++;
      } else {
        pendingTotal += p.amount;
        pendingCount++;
      }
    }

    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    // Filter payments
    final filteredPayments = rawPayments.where((p) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.id.toLowerCase().contains(query) ||
          p.transactionId.toLowerCase().contains(query) ||
          p.paymentId.toLowerCase().contains(query) ||
          p.invoiceNumber.toLowerCase().contains(query) ||
          p.recipientName.toLowerCase().contains(query) ||
          (p.chequeNumber != null && p.chequeNumber!.toLowerCase().contains(query));

      final matchesMethod = _methodFilter == 'All' ||
          p.paymentMethod.toLowerCase() == _methodFilter.toLowerCase();

      bool matchesStatus = true;
      if (_statusFilter != 'All') {
        final sf = _statusFilter.toLowerCase();
        final st = p.paymentStatus.toLowerCase();
        if (sf == 'overdue') {
          final schDate = p.scheduledPaymentDate;
          matchesStatus = st.contains('overdue') ||
              (st.contains('pending') && schDate != null && schDate.isBefore(todayDate));
        } else if (sf.contains('paid')) {
          matchesStatus = st.contains('paid') || st.contains('completed');
        } else if (sf.contains('pending')) {
          matchesStatus = st.contains('pending');
        } else if (sf.contains('scheduled')) {
          matchesStatus = st.contains('scheduled');
        } else {
          matchesStatus = st == sf;
        }
      }

      bool matchesDate = true;
      if (_selectedDateRange != null) {
        final pDate = p.paymentDate;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        matchesDate = pDate.isAfter(start.subtract(const Duration(seconds: 1))) && pDate.isBefore(end);
      }

      return matchesSearch && matchesMethod && matchesStatus && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier Payments',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A2332),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record supplier payments, manage cheques, track pending bills, and monitor scheduled dates.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting CSV...')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export CSV'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openAddEditPaymentDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'Add Payment',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            // Summary KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Payments',
                    value: formatCurrency.format(totalAmount),
                    subtitle: '${rawPayments.length} Total Records',
                    icon: Icons.payments,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Paid Total',
                    value: formatCurrency.format(paidTotal),
                    subtitle: 'Completed Transactions',
                    icon: Icons.check_circle_outline,
                    color: AppColors.statusGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pending Payments',
                    value: formatCurrency.format(pendingTotal),
                    subtitle: '$pendingCount Pending | $overdueCount Overdue',
                    icon: Icons.hourglass_empty,
                    color: overdueCount > 0 ? AppColors.statusRed : AppColors.accentOrange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Scheduled Payments',
                    value: formatCurrency.format(scheduledTotal),
                    subtitle: '$scheduledCount Future Due Dates',
                    icon: Icons.event,
                    color: AppColors.accentTeal,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filter Toolbar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.bgDarkBorder : const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search Supplier Name, Invoice #, Payment ID, Cheque #...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Payment Method Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _methodFilter,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['All', 'Card Payment', 'Cheque', 'Bank Transfer', 'Cash']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _methodFilter = val!),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Payment Status Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['All', 'Paid', 'Pending Payment', 'Scheduled Payment', 'Overdue']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _statusFilter = val!),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date Range Picker Button
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _selectedDateRange != null ? AppColors.primary : null,
                        fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Clear Filters
                  if (_searchQuery.isNotEmpty || _methodFilter != 'All' || _statusFilter != 'All' || _selectedDateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _methodFilter = 'All';
                          _statusFilter = 'All';
                          _selectedDateRange = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                      label: const Text('Reset', style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payments Data Table
            Expanded(
              child: Card(
                color: isDark ? AppColors.bgDarkCard : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.bgDarkBorder : const Color(0xFFE5E7EB)),
                ),
                child: _buildDataTable(context, filteredPayments, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<PaymentModel> payments, bool isDark) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No supplier payments found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "+ Add Payment" to record a new supplier payment.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return PaginatedDataTable2(
      minWidth: 1250,
      columns: const [
        DataColumn2(label: Text('Payment ID'), fixedWidth: 150),
        DataColumn2(label: Text('Supplier Name'), size: ColumnSize.L),
        DataColumn2(label: Text('Invoice #'), fixedWidth: 110),
        DataColumn2(label: Text('Amount'), fixedWidth: 110, numeric: true),
        DataColumn2(label: Text('Payment Method'), fixedWidth: 150),
        DataColumn2(label: Text('Date of Issue'), fixedWidth: 120),
        DataColumn2(label: Text('Scheduled Payment Date'), fixedWidth: 190),
        DataColumn2(label: Text('Status'), fixedWidth: 150),
        DataColumn2(label: Text('Actions'), fixedWidth: 120),
      ],
      source: _PaymentsDataSource(context, payments, ref, isDark, (payment) {
        _openAddEditPaymentDialog(context, payment: payment);
      }),
      rowsPerPage: 10,
    );
  }

  void _openAddEditPaymentDialog(BuildContext context, {PaymentModel? payment}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddEditPaymentDialog(paymentToEdit: payment),
    );
  }
}

// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.bgDarkCard : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.bgDarkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Source for PaginatedDataTable2
class _PaymentsDataSource extends DataTableSource {
  final BuildContext context;
  final List<PaymentModel> payments;
  final WidgetRef ref;
  final bool isDark;
  final Function(PaymentModel) onEdit;

  _PaymentsDataSource(this.context, this.payments, this.ref, this.isDark, this.onEdit);

  @override
  DataRow? getRow(int index) {
    if (index >= payments.length) return null;
    final p = payments[index];
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final displayTxId = p.id.isNotEmpty ? p.id : (p.paymentId.isNotEmpty ? p.paymentId : 'PAY-1001');
    final invoiceRef = p.invoiceNumber.isNotEmpty ? p.invoiceNumber : (p.orderId.isNotEmpty ? p.orderId : 'INV-GENERAL');

    final schDate = p.scheduledPaymentDate;
    final isOverdue = p.paymentStatus.toLowerCase().contains('overdue') ||
        (p.paymentStatus.toLowerCase().contains('pending') && schDate != null && schDate.isBefore(todayDate));

    return DataRow2(
      cells: [
        // 1. Payment ID
        DataCell(
          Text(
            displayTxId,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        // 2. Supplier Name
        DataCell(
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.recipientName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 3. Invoice #
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              invoiceRef,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // 4. Amount
        DataCell(
          Text(
            formatCurrency.format(p.amount),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        // 5. Payment Method
        DataCell(_buildMethodBadge(p)),

        // 6. Date of Issue
        DataCell(
          Text(
            DateFormat('dd MMM yyyy').format(p.paymentDate),
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),

        // 7. Scheduled Payment Date (DEDICATED COLUMN!)
        DataCell(_buildScheduledDateCell(schDate, isOverdue, p.paymentStatus)),

        // 8. Status
        DataCell(_buildStatusBadge(p.paymentStatus, isOverdue)),

        // 9. Actions
        DataCell(
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Details
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () => _showPaymentDetailsModal(context, p),
                ),
                const SizedBox(width: 4),

                // Edit / Update
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                  tooltip: 'Edit Payment',
                  onPressed: () => onEdit(p),
                ),
                const SizedBox(width: 4),

                // Delete
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  tooltip: 'Delete Payment',
                  onPressed: () => _confirmDeletePayment(context, p),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodBadge(PaymentModel p) {
    final method = p.paymentMethod;
    IconData icon = Icons.money;
    Color color = Colors.green;

    final m = method.toLowerCase();
    if (m.contains('card')) {
      icon = Icons.credit_card;
      color = Colors.blue;
    } else if (m.contains('cheque')) {
      icon = Icons.assignment;
      color = Colors.amber.shade800;
    } else if (m.contains('transfer') || m.contains('bank')) {
      icon = Icons.account_balance;
      color = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              method,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledDateCell(DateTime? schDate, bool isOverdue, String status) {
    if (schDate == null) {
      return Text('-', style: GoogleFonts.inter(color: Colors.grey));
    }

    final dateStr = DateFormat('dd MMM yyyy').format(schDate);
    final st = status.toLowerCase();

    Color bgColor = Colors.grey.withValues(alpha: 0.1);
    Color textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    IconData? alertIcon;

    if (st.contains('paid') || st.contains('completed')) {
      bgColor = Colors.green.withValues(alpha: 0.08);
      textColor = Colors.green.shade700;
    } else if (isOverdue) {
      bgColor = Colors.red.withValues(alpha: 0.12);
      textColor = Colors.red.shade700;
      alertIcon = Icons.warning_amber;
    } else if (st.contains('scheduled') || st.contains('pending')) {
      bgColor = Colors.blue.withValues(alpha: 0.12);
      textColor = Colors.blue.shade700;
      alertIcon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isOverdue ? Border.all(color: Colors.red.shade300) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alertIcon != null) ...[
            Icon(alertIcon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOverdue) {
    String displayStatus = status;
    Color color = Colors.grey;

    final s = status.toLowerCase();
    if (s.contains('paid') || s.contains('completed')) {
      displayStatus = 'Paid';
      color = AppColors.statusGreen;
    } else if (isOverdue || s.contains('overdue')) {
      displayStatus = 'Overdue';
      color = AppColors.statusRed;
    } else if (s.contains('scheduled')) {
      displayStatus = 'Scheduled Payment';
      color = AppColors.accentTeal;
    } else if (s.contains('pending')) {
      displayStatus = 'Pending Payment';
      color = AppColors.accentOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, PaymentModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Supplier Payment?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete payment ${p.id} for "${p.recipientName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(paymentRepositoryProvider).deletePayment(p.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment ${p.id} deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailsModal(BuildContext context, PaymentModel p) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Payment Details',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              _detailRow('Payment ID', p.id),
              _detailRow('Supplier / Recipient', p.recipientName),
              _detailRow('Invoice Number', p.invoiceNumber.isNotEmpty ? p.invoiceNumber : 'N/A'),
              _detailRow('Amount', formatCurrency.format(p.amount), isBold: true),
              _detailRow('Payment Method', p.paymentMethod),
              _detailRow('Payment Status', p.paymentStatus),
              _detailRow('Date of Issue', DateFormat('dd MMMM yyyy').format(p.paymentDate)),

              if (p.scheduledPaymentDate != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.blue),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scheduled Payment Date', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade900)),
                          Text(
                            DateFormat('dd MMMM yyyy').format(p.scheduledPaymentDate!),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (p.paymentMethod.toLowerCase().contains('cheque')) ...[
                const SizedBox(height: 12),
                Text('Cheque Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                _detailRow('Cheque Number', p.chequeNumber ?? 'N/A'),
                _detailRow('Cheque Status', p.chequeStatus ?? 'Pending'),
                if (p.chequeAmount != null) _detailRow('Cheque Amount', formatCurrency.format(p.chequeAmount!)),
              ],

              if (p.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notes / Comments', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(p.notes, style: GoogleFonts.inter(color: Colors.grey.shade800)),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print Receipt'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  int get rowCount => payments.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

// Add & Edit Payment Form Dialog Modal
class _AddEditPaymentDialog extends ConsumerStatefulWidget {
  final PaymentModel? paymentToEdit;

  const _AddEditPaymentDialog({this.paymentToEdit});

  @override
  ConsumerState<_AddEditPaymentDialog> createState() => _AddEditPaymentDialogState();
}

class _AddEditPaymentDialogState extends ConsumerState<_AddEditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _supplierNameController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _amountController;
  late TextEditingController _chequeNumberController;
  late TextEditingController _chequeAmountController;
  late TextEditingController _notesController;

  SupplierModel? _selectedSupplier;
  String _paymentMethod = 'Cash';
  String _paymentStatus = 'Paid';
  String _chequeStatus = 'Pending';
  DateTime _dateOfIssue = DateTime.now();
  DateTime? _scheduledDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.paymentToEdit;

    _supplierNameController = TextEditingController(text: p?.recipientName ?? '');
    _invoiceNumberController = TextEditingController(text: p?.invoiceNumber ?? '');
    _amountController = TextEditingController(text: p != null && p.amount > 0 ? p.amount.toStringAsFixed(2) : '');
    _chequeNumberController = TextEditingController(text: p?.chequeNumber ?? '');
    _chequeAmountController = TextEditingController(text: p?.chequeAmount != null ? p!.chequeAmount!.toStringAsFixed(2) : '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    if (p != null) {
      final methodMatches = ['Card Payment', 'Cheque', 'Bank Transfer', 'Cash'];
      _paymentMethod = methodMatches.firstWhere(
        (m) => m.toLowerCase() == p.paymentMethod.toLowerCase(),
        orElse: () => p.paymentMethod.isNotEmpty ? p.paymentMethod : 'Cash',
      );

      final statusMatches = ['Paid', 'Pending Payment', 'Scheduled Payment', 'Overdue'];
      _paymentStatus = statusMatches.firstWhere(
        (s) => s.toLowerCase() == p.paymentStatus.toLowerCase() ||
               (s.toLowerCase().contains('pending') && p.paymentStatus.toLowerCase().contains('pending')) ||
               (s.toLowerCase().contains('paid') && p.paymentStatus.toLowerCase().contains('paid')) ||
               (s.toLowerCase().contains('scheduled') && p.paymentStatus.toLowerCase().contains('scheduled')) ||
               (s.toLowerCase().contains('overdue') && p.paymentStatus.toLowerCase().contains('overdue')),
        orElse: () => p.paymentStatus.isNotEmpty ? p.paymentStatus : 'Paid',
      );

      final chqStatusMatches = ['Pending', 'Cleared', 'Bounced', 'Cancelled'];
      _chequeStatus = chqStatusMatches.firstWhere(
        (c) => c.toLowerCase() == (p.chequeStatus ?? '').toLowerCase(),
        orElse: () => 'Pending',
      );

      _dateOfIssue = p.paymentDate;
      _scheduledDate = p.scheduledPaymentDate;
    }
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _chequeNumberController.dispose();
    _chequeAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(firestoreSuppliersProvider);
    final suppliers = suppliersAsync.maybeWhen(data: (list) => list, orElse: () => []);
    final isEditing = widget.paymentToEdit != null;
    final isCheque = _paymentMethod.toLowerCase().contains('cheque');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Supplier Payment' : 'Add Supplier Payment',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Supplier Selection
                      Text('1. Supplier Information', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<SupplierModel>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Supplier from Database',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: suppliers.contains(_selectedSupplier) ? _selectedSupplier : null,
                              items: suppliers.map((sup) {
                                return DropdownMenuItem<SupplierModel>(
                                  value: sup,
                                  child: Text(sup.companyName, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSupplier = val;
                                  if (val != null) {
                                    _supplierNameController.text = val.companyName;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _supplierNameController,
                              decoration: const InputDecoration(
                                labelText: 'Or Enter Supplier Name *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter supplier name' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Invoice & Amount
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Number (e.g. INV-8821)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Payment Amount (LKR / Rs.) *',
                                prefixText: 'Rs. ',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter amount';
                                if (double.tryParse(val) == null) return 'Invalid amount';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Payment Method & Status
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: {
                                ...['Card Payment', 'Cheque', 'Bank Transfer', 'Cash'],
                                _paymentMethod,
                              }
                                  .where((m) => m.isNotEmpty)
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _paymentStatus,
                              decoration: const InputDecoration(
                                labelText: 'Payment Status *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: {
                                ...['Paid', 'Pending Payment', 'Scheduled Payment', 'Overdue'],
                                _paymentStatus,
                              }
                                  .where((s) => s.isNotEmpty)
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) => setState(() => _paymentStatus = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Issue Date & Scheduled Date Pickers
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfIssue,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _dateOfIssue = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Issue *',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                child: Text(DateFormat('dd MMM yyyy').format(_dateOfIssue)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _scheduledDate = picked);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Scheduled Payment Date',
                                  hintText: 'Select Due Date',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_scheduledDate != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () => setState(() => _scheduledDate = null),
                                        ),
                                      const Icon(Icons.event, size: 18),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  _scheduledDate != null
                                      ? DateFormat('dd MMM yyyy').format(_scheduledDate!)
                                      : 'Not Scheduled',
                                  style: TextStyle(
                                    color: _scheduledDate != null ? AppColors.primary : Colors.grey,
                                    fontWeight: _scheduledDate != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Cheque Details Section (Only when method is Cheque)
                      if (isCheque) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assignment, color: Colors.amber.shade900, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cheque Details',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _chequeNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cheque Number (e.g. CHQ-994821)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _chequeStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Cheque Status',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: {
                                        ...['Pending', 'Cleared', 'Bounced', 'Cancelled'],
                                        _chequeStatus,
                                      }
                                          .where((s) => s.isNotEmpty)
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _chequeStatus = val!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _chequeAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Cheque Amount (LKR / Rs.)',
                                  prefixText: 'Rs. ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 6. Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Comments (Optional)',
                          hintText: 'e.g., Payment scheduled for end of month supply clearance...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Submit Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _savePayment,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, size: 18),
                    label: Text(isEditing ? 'Update Payment' : 'Save Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final chqAmt = double.tryParse(_chequeAmountController.text.trim());

      final paymentId = widget.paymentToEdit?.id ?? 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final payment = PaymentModel(
        id: paymentId,
        paymentId: paymentId,
        transactionId: paymentId,
        supplierId: _selectedSupplier?.id ?? '',
        supplierName: _supplierNameController.text.trim(),
        customerName: _supplierNameController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim(),
        amount: amt,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        paymentDate: _dateOfIssue,
        scheduledDate: _scheduledDate,
        chequeNumber: _chequeNumberController.text.trim().isNotEmpty ? _chequeNumberController.text.trim() : null,
        chequeStatus: _paymentMethod.toLowerCase().contains('cheque') ? _chequeStatus : null,
        chequeAmount: chqAmt,
        chequeIssueDate: _paymentMethod.toLowerCase().contains('cheque') ? _dateOfIssue : null,
        chequeDueDate: _paymentMethod.toLowerCase().contains('cheque') ? _scheduledDate : null,
        notes: _notesController.text.trim(),
        createdAt: widget.paymentToEdit?.createdAt ?? DateTime.now(),
      );

      final repo = ref.read(paymentRepositoryProvider);
      if (widget.paymentToEdit != null) {
        await repo.updatePayment(payment);
      } else {
        await repo.addPayment(payment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.paymentToEdit != null
                  ? 'Payment ${payment.id} updated successfully'
                  : 'Supplier Payment saved successfully',
            ),
            backgroundColor: AppColors.statusGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving payment: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
