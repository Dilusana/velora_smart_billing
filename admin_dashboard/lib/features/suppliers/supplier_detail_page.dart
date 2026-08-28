import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../core/theme/app_theme.dart';

class SupplierDetailPage extends ConsumerStatefulWidget {
  final String id;
  const SupplierDetailPage({super.key, required this.id});

  @override
  ConsumerState<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends ConsumerState<SupplierDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, dynamic> supplier = {
    'id': '1',
    'name': 'Global Tech Supplies',
    'contact_person': 'Jane Doe',
    'phone': '+1 234 567 890',
    'email': 'jane@globaltech.com',
    'address': '123 Tech Lane, Innovation City',
    'payment_terms': 'Net 30',
  };

  final List<Map<String, dynamic>> pos = [
    {
      'po': 'PO-2023-001',
      'date': '2023-10-01',
      'items': 150,
      'total': 12500.00,
      'expected': '2023-10-15',
      'status': 'Confirmed',
    },
    {
      'po': 'PO-2023-002',
      'date': '2023-10-05',
      'items': 50,
      'total': 3000.00,
      'expected': '2023-10-20',
      'status': 'Sent',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showCreatePODialog(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Purchase Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    FormBuilderDateTimePicker(
                      name: 'expected_date',
                      decoration: const InputDecoration(labelText: 'Expected Delivery Date', border: OutlineInputBorder()),
                      inputType: InputType.date,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Products', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Dummy product selection
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Product A x 100'),
                          Text('Rs. 5,000.00'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('Total: Rs. 5,000.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            if (formKey.currentState?.saveAndValidate() ?? false) {
                              Navigator.pop(context);
                              toastification.show(
                                context: context,
                                title: const Text('Success'),
                                description: const Text('Purchase Order Created and Sent.'),
                                type: ToastificationType.success,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }
                          },
                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return AppColors.statusGreen;
      case 'Sent': return AppColors.statusBlue;
      case 'Draft': return AppColors.statusGray;
      default: return AppColors.textPrimary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Confirmed': return AppColors.statusGreenBg;
      case 'Sent': return AppColors.statusBlueBg;
      case 'Draft': return AppColors.statusGrayBg;
      default: return Colors.grey.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                Text(
                  supplier['name'],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCreatePODialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Create Purchase Order', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 5,
                children: [
                  _buildInfoItem('Contact Person', supplier['contact_person']),
                  _buildInfoItem('Phone', supplier['phone']),
                  _buildInfoItem('Email', supplier['email']),
                  _buildInfoItem('Address', supplier['address']),
                  _buildInfoItem('Payment Terms', supplier['payment_terms']),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Purchase Orders'),
                Tab(text: 'Contact Log'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPOTable(isDark),
                  _buildContactLog(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPOTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        columns: const [
          DataColumn2(label: Text('PO #')),
          DataColumn2(label: Text('Date')),
          DataColumn2(label: Text('Items')),
          DataColumn2(label: Text('Total (Rs)')),
          DataColumn2(label: Text('Expected')),
          DataColumn2(label: Text('Status')),
          DataColumn2(label: Text('Actions')),
        ],
        rows: pos.map((po) {
          return DataRow(cells: [
            DataCell(Text(po['po'])),
            DataCell(Text(po['date'])),
            DataCell(Text(po['items'].toString())),
            DataCell(Text(po['total'].toStringAsFixed(2))),
            DataCell(Text(po['expected'])),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(po['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  po['status'],
                  style: TextStyle(color: _getStatusColor(po['status']), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.visibility, color: AppColors.statusBlue), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.check_circle, color: AppColors.statusGreen), onPressed: () {}),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildContactLog(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: const Center(child: Text('Contact log timeline...')),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
