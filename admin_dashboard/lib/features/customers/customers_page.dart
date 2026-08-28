import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:toastification/toastification.dart';

import '../../core/data/models.dart';
import '../../core/theme/app_theme.dart';
import 'customer_providers.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _loyaltyFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final formKey = GlobalKey<FormBuilderState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCustomerDialog(BuildContext context, [CustomerModel? customerToEdit]) {
    final isEditing = customerToEdit != null;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: formKey,
                initialValue: isEditing
                    ? {
                        'name': customerToEdit.name,
                        'email': customerToEdit.email,
                        'phone': customerToEdit.phone,
                        'address': customerToEdit.address,
                        'loyaltyTier': customerToEdit.loyaltyTier,
                        'loyaltyPoints': customerToEdit.loyaltyPoints.toString(),
                        'status': customerToEdit.status,
                      }
                    : {
                        'loyaltyTier': 'Bronze',
                        'loyaltyPoints': '0',
                        'status': 'Active',
                      },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Customer' : 'Add Customer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    FormBuilderTextField(
                      name: 'name',
                      decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'email',
                            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'phone',
                            decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'address',
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderDropdown<String>(
                            name: 'loyaltyTier',
                            decoration: const InputDecoration(labelText: 'Loyalty Tier', border: OutlineInputBorder()),
                            items: ['Bronze', 'Silver', 'Gold', 'Platinum']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'loyaltyPoints',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Loyalty Points', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () async {
                            if (formKey.currentState?.saveAndValidate() ?? false) {
                              final val = formKey.currentState!.value;
                              final pts = int.tryParse((val['loyaltyPoints'] ?? '0').toString()) ?? 0;

                              final customer = CustomerModel(
                                id: isEditing ? customerToEdit.id : '',
                                name: (val['name'] ?? '').toString().trim(),
                                email: (val['email'] ?? '').toString().trim(),
                                phone: (val['phone'] ?? '').toString().trim(),
                                address: (val['address'] ?? '').toString().trim(),
                                loyaltyTier: (val['loyaltyTier'] ?? 'Bronze').toString(),
                                loyaltyPoints: pts,
                                status: (val['status'] ?? 'Active').toString(),
                                totalOrders: customerToEdit?.totalOrders ?? 0,
                                totalSpend: customerToEdit?.totalSpend ?? 0.0,
                                lastOrderDate: customerToEdit?.lastOrderDate ?? DateTime.now(),
                                joinDate: customerToEdit?.joinDate ?? DateTime.now(),
                              );

                              try {
                                final repo = ref.read(customerRepositoryProvider);
                                if (isEditing) {
                                  await repo.updateCustomer(customer);
                                } else {
                                  await repo.addCustomer(customer);
                                }

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  toastification.show(
                                    context: context,
                                    title: Text(isEditing ? 'Customer Updated' : 'Customer Added'),
                                    description: Text('${customer.name} saved to Cloud Firestore.'),
                                    type: ToastificationType.success,
                                    autoCloseDuration: const Duration(seconds: 3),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  toastification.show(
                                    context: context,
                                    title: const Text('Error Saving Customer'),
                                    description: Text(e.toString()),
                                    type: ToastificationType.error,
                                  );
                                }
                              }
                            }
                          },
                          child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final firestoreCustomersAsync = ref.watch(firestoreCustomersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
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
                color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                ),
                child: firestoreCustomersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading customers: $err')),
                  data: (rawCustomers) {
                    final filteredCustomers = rawCustomers.where((customer) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          customer.phone.contains(_searchQuery);

                      final matchesTier = _loyaltyFilter == 'All' ||
                          customer.loyaltyTier.toLowerCase() == _loyaltyFilter.toLowerCase();

                      return matchesSearch && matchesTier;
                    }).toList();

                    if (filteredCustomers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No customers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditCustomerDialog(context),
                              icon: const Icon(Icons.person_add, color: Colors.white),
                              label: const Text('Add First Customer', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildDataTable(filteredCustomers);
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
          'Customers',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddEditCustomerDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
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
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search Customers by name, email, or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _loyaltyFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            items: ['All', 'Bronze', 'Silver', 'Gold', 'Platinum']
                .map((s) => DropdownMenuItem(value: s, child: Text('Tier: $s', overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => _loyaltyFilter = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<CustomerModel> customers) {
    return PaginatedDataTable2(
      columns: const [
        DataColumn2(label: Text('Customer'), size: ColumnSize.L),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Phone'), size: ColumnSize.M),
        DataColumn2(label: Text('Orders'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Total Spend'), size: ColumnSize.M, numeric: true),
        DataColumn2(label: Text('Tier'), size: ColumnSize.S),
        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
      ],
      source: _CustomersDataSource(context, customers, (c) => _showAddEditCustomerDialog(context, c)),
      rowsPerPage: 10,
    );
  }
}

class _CustomersDataSource extends DataTableSource {
  final BuildContext context;
  final List<CustomerModel> customers;
  final Function(CustomerModel) onEdit;

  _CustomersDataSource(this.context, this.customers, this.onEdit);

  @override
  DataRow? getRow(int index) {
    if (index >= customers.length) return null;
    final customer = customers[index];
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    return DataRow2(
      onSelectChanged: (_) {
        context.go('/customers/${customer.id}');
      },
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )),
        DataCell(Text(customer.email.isNotEmpty ? customer.email : '—')),
        DataCell(Text(customer.phone.isNotEmpty ? customer.phone : '—')),
        DataCell(Text('${customer.totalOrders}')),
        DataCell(Text(formatCurrency.format(customer.totalSpend))),
        DataCell(_buildTierBadge(customer.loyaltyTier)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: 'View Profile',
              onPressed: () => context.go('/customers/${customer.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit',
              onPressed: () => onEdit(customer),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color = Colors.grey;
    if (tier.toLowerCase() == 'bronze') color = Colors.orange;
    if (tier.toLowerCase() == 'silver') color = Colors.blueGrey;
    if (tier.toLowerCase() == 'gold') color = Colors.amber.shade700;
    if (tier.toLowerCase() == 'platinum') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(tier, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => customers.length;
  @override
  int get selectedRowCount => 0;
}
