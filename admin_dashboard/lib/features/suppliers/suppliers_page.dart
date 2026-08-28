import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import 'supplier_providers.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditSupplierDialog(BuildContext context, [SupplierModel? supplier]) {
    final formKey = GlobalKey<FormBuilderState>();
    final isEdit = supplier != null;

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
                initialValue: isEdit
                    ? {
                        'companyName': supplier.companyName,
                        'contactPerson': supplier.contactPerson,
                        'phone': supplier.phone,
                        'email': supplier.email,
                        'address': supplier.address,
                        'status': supplier.status,
                      }
                    : {
                        'status': 'active',
                      },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Supplier' : 'Add Supplier',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    FormBuilderTextField(
                      name: 'companyName',
                      decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'contactPerson',
                            decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder()),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'phone',
                            decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'address',
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: 'status',
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: ['active', 'inactive']
                          .map((st) => DropdownMenuItem(value: st, child: Text(st.toUpperCase())))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () async {
                            if (formKey.currentState?.saveAndValidate() ?? false) {
                              final values = formKey.currentState!.value;
                              final newSupplier = SupplierModel(
                                id: supplier?.id ?? '',
                                companyName: (values['companyName'] ?? '').toString(),
                                contactPerson: (values['contactPerson'] ?? '').toString(),
                                phone: (values['phone'] ?? '').toString(),
                                email: (values['email'] ?? '').toString(),
                                address: (values['address'] ?? '').toString(),
                                status: (values['status'] ?? 'active').toString(),
                              );

                              final repo = ref.read(supplierRepositoryProvider);
                              if (isEdit) {
                                await repo.updateSupplier(newSupplier);
                              } else {
                                await repo.addSupplier(newSupplier);
                              }

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                toastification.show(
                                  context: context,
                                  title: const Text('Success'),
                                  description: Text(isEdit ? 'Supplier updated in Cloud Firestore' : 'Supplier added to Cloud Firestore'),
                                  type: ToastificationType.success,
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                              }
                            }
                          },
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestoreSuppliersAsync = ref.watch(firestoreSuppliersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suppliers',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditSupplierDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Supplier', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
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
                      hintText: 'Search Supplier Name, Contact Person, Email or Phone',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                ),
                child: firestoreSuppliersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading suppliers: $err')),
                  data: (rawSuppliers) {
                    final filteredSuppliers = rawSuppliers.where((s) {
                      return _searchQuery.isEmpty ||
                          s.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          s.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          s.phone.contains(_searchQuery) ||
                          s.email.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredSuppliers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No suppliers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditSupplierDialog(context),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add First Supplier', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }

                    return DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 1000,
                  columns: const [
                    DataColumn2(label: Text('Company Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('Contact Person'), size: ColumnSize.M),
                    DataColumn2(label: Text('Phone'), size: ColumnSize.M),
                    DataColumn2(label: Text('Email'), size: ColumnSize.L),
                    DataColumn2(label: Text('Address'), size: ColumnSize.L),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                  ],
                  rows: filteredSuppliers.map((supplier) {
                    final isStatusActive = supplier.status.toLowerCase() == 'active';
                    return DataRow(cells: [
                      DataCell(Text(supplier.companyName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(supplier.contactPerson)),
                      DataCell(Text(supplier.phone)),
                      DataCell(Text(supplier.email)),
                      DataCell(Text(supplier.address)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isStatusActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            supplier.status.toUpperCase(),
                            style: TextStyle(
                              color: isStatusActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.statusAmber),
                              onPressed: () => _showAddEditSupplierDialog(context, supplier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.statusRed),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Supplier'),
                                    content: Text('Are you sure you want to delete ${supplier.companyName}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
