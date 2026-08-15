import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:toastification/toastification.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import 'employee_providers.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  final formKey = GlobalKey<FormBuilderState>();

  void _showAddEditEmployeeDialog(BuildContext context, [EmployeeModel? employeeToEdit]) {
    final isEditing = employeeToEdit != null;

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
                        'name': employeeToEdit.name,
                        'email': employeeToEdit.email,
                        'phone': employeeToEdit.phone,
                        'role': employeeToEdit.role,
                        'branch': employeeToEdit.branch,
                        'status': employeeToEdit.status,
                        'salary': employeeToEdit.salary.toString(),
                      }
                    : {
                        'role': 'Cashier',
                        'branch': 'Main Branch',
                        'status': 'Active',
                      },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Employee' : 'Add Employee',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    FormBuilderTextField(
                      name: 'name',
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'email',
                            decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
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
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderDropdown<String>(
                            name: 'role',
                            decoration: const InputDecoration(labelText: 'Role *', border: OutlineInputBorder()),
                            validator: FormBuilderValidators.required(),
                            items: ['Super Admin', 'Admin', 'Manager', 'Cashier', 'Employee']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'branch',
                            decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'salary',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Monthly Salary (Rs.)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderDropdown<String>(
                            name: 'status',
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: ['Active', 'Inactive']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
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
                              final sal = double.tryParse((val['salary'] ?? '0').toString()) ?? 0.0;

                              final emp = EmployeeModel(
                                id: isEditing ? employeeToEdit.id : 'emp_${DateTime.now().millisecondsSinceEpoch}',
                                name: (val['name'] ?? '').toString().trim(),
                                role: (val['role'] ?? 'Employee').toString(),
                                branch: (val['branch'] ?? 'Main Branch').toString(),
                                phone: (val['phone'] ?? '').toString().trim(),
                                email: (val['email'] ?? '').toString().trim(),
                                status: (val['status'] ?? 'Active').toString(),
                                hireDate: employeeToEdit?.hireDate ?? DateTime.now(),
                                salary: sal,
                                permissions: employeeToEdit?.permissions ?? const [],
                              );

                              try {
                                if (isEditing) {
                                  await ref.read(firestoreEmployeesProvider.notifier).updateEmployee(emp);
                                } else {
                                  await ref.read(firestoreEmployeesProvider.notifier).add(emp);
                                }
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  toastification.show(
                                    context: context,
                                    title: Text(isEditing ? 'Employee Updated' : 'Employee Added'),
                                    description: Text('${emp.name} saved to Cloud Firestore.'),
                                    type: ToastificationType.success,
                                    autoCloseDuration: const Duration(seconds: 3),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  toastification.show(
                                    context: context,
                                    title: const Text('Error Saving Employee'),
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

  void _confirmDelete(BuildContext context, EmployeeModel emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete "${emp.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(firestoreEmployeesProvider.notifier).delete(emp.id);
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Employee Deleted'),
                    type: ToastificationType.info,
                  );
                }
              } catch (e) {
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Error Deleting Employee'),
                    description: Text(e.toString()),
                    type: ToastificationType.error,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employeesAsync = ref.watch(firestoreEmployeesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Employees', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditEmployeeDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Employee', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                child: employeesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading employees: $err')),
                  data: (employees) {
                    if (employees.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No employees found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditEmployeeDialog(context),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add First Employee', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }

                    return DataTable2(
                      columns: const [
                        DataColumn2(label: Text('Avatar'), fixedWidth: 60),
                        DataColumn2(label: Text('Name')),
                        DataColumn2(label: Text('Role')),
                        DataColumn2(label: Text('Branch')),
                        DataColumn2(label: Text('Phone')),
                        DataColumn2(label: Text('Status')),
                        DataColumn2(label: Text('Actions')),
                      ],
                      rows: employees.map((emp) => DataRow(
                        cells: [
                          DataCell(CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          )),
                          DataCell(Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(emp.role)),
                          DataCell(Text(emp.branch)),
                          DataCell(Text(emp.phone)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: emp.status.toLowerCase() == 'active'
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                emp.status.toUpperCase(),
                                style: TextStyle(
                                  color: emp.status.toLowerCase() == 'active' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                tooltip: 'View Profile',
                                onPressed: () => context.go('/employees/${emp.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                onPressed: () => _showAddEditEmployeeDialog(context, emp),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusRed),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(context, emp),
                              ),
                            ],
                          )),
                        ]
                      )).toList(),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
