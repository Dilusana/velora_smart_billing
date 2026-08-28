import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../customers/customer_providers.dart';
import '../employees/employee_providers.dart';
import 'notification_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNotificationDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String targetType = 'all'; // 'all' or 'specific'
    String? selectedCustomerId;
    String selectedCustomerName = '';

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final customersAsync = ref.watch(firestoreCustomersProvider);
            final List<CustomerModel> customers = customersAsync.value ?? [];

            final employeesAsync = ref.watch(firestoreEmployeesProvider);
            final List<EmployeeModel> employees = employeesAsync.value ?? [];

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
              child: Container(
                width: 620,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Send Push Notification (FCM)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Target Audience',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.people_alt_outlined, size: 16),
                          label: const Text('All Users'),
                          selected: targetType == 'all',
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: targetType == 'all' ? AppColors.primary : null,
                            fontWeight: targetType == 'all' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                targetType = 'all';
                                selectedCustomerId = null;
                                selectedCustomerName = 'All Users';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.badge_outlined, size: 16),
                          label: const Text('All Employees'),
                          selected: targetType == 'all_employees',
                          selectedColor: Colors.purple.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: targetType == 'all_employees' ? Colors.purple : null,
                            fontWeight: targetType == 'all_employees' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                targetType = 'all_employees';
                                selectedCustomerId = null;
                                selectedCustomerName = 'All Employees';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.person_outline_rounded, size: 16),
                          label: const Text('Specific Customer'),
                          selected: targetType == 'specific',
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: targetType == 'specific' ? AppColors.primary : null,
                            fontWeight: targetType == 'specific' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                targetType = 'specific';
                                selectedCustomerId = null;
                                selectedCustomerName = '';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.assignment_ind_outlined, size: 16),
                          label: const Text('Specific Employee'),
                          selected: targetType == 'specific_employee',
                          selectedColor: Colors.purple.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: targetType == 'specific_employee' ? Colors.purple : null,
                            fontWeight: targetType == 'specific_employee' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                targetType = 'specific_employee';
                                selectedCustomerId = null;
                                selectedCustomerName = '';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (targetType == 'specific') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Customer *',
                          hintText: 'Choose recipient customer',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.person_search_outlined),
                        ),
                        value: selectedCustomerId,
                        items: customers.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text('${c.name} (${c.email.isNotEmpty ? c.email : c.phone})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final cust = customers.firstWhere((c) => c.id == val);
                            setDialogState(() {
                              selectedCustomerId = val;
                              selectedCustomerName = cust.name;
                            });
                          }
                        },
                      ),
                    ],
                    if (targetType == 'specific_employee') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Employee *',
                          hintText: 'Choose recipient employee',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        value: selectedCustomerId,
                        items: employees.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.id,
                            child: Text('${e.name} - ${e.role} (${e.email.isNotEmpty ? e.email : e.phone})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final emp = employees.firstWhere((e) => e.id == val);
                            setDialogState(() {
                              selectedCustomerId = val;
                              selectedCustomerName = '${emp.name} (${emp.role})';
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title *',
                        hintText: 'e.g. Shift Update / Special Announcement',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message Body *',
                        hintText: 'Enter push notification message content...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            final message = messageCtrl.text.trim();

                            if (title.isEmpty) {
                              toastification.show(
                                context: context,
                                title: const Text('Validation Error'),
                                description: const Text('Please enter a notification title.'),
                                type: ToastificationType.error,
                              );
                              return;
                            }

                            if (message.isEmpty) {
                              toastification.show(
                                context: context,
                                title: const Text('Validation Error'),
                                description: const Text('Please enter a message body.'),
                                type: ToastificationType.error,
                              );
                              return;
                            }

                            if ((targetType == 'specific' || targetType == 'specific_employee') &&
                                (selectedCustomerId == null || selectedCustomerId!.isEmpty)) {
                              toastification.show(
                                context: context,
                                title: const Text('Validation Error'),
                                description: Text(
                                  targetType == 'specific_employee'
                                      ? 'Please select a specific employee recipient.'
                                      : 'Please select a specific customer recipient.',
                                ),
                                type: ToastificationType.error,
                              );
                              return;
                            }

                            String resolvedTargetName = 'All Users';
                            if (targetType == 'all_employees') {
                              resolvedTargetName = 'All Employees';
                            } else if (targetType == 'specific' || targetType == 'specific_employee') {
                              resolvedTargetName = selectedCustomerName;
                            }

                            try {
                              await ref.read(notificationRepositoryProvider).sendNotification(
                                    title: title,
                                    message: message,
                                    targetType: targetType,
                                    targetUserId: selectedCustomerId ?? '',
                                    targetUserName: resolvedTargetName,
                                  );

                              if (mounted) {
                                Navigator.pop(context);
                                toastification.show(
                                  context: context,
                                  title: const Text('Notification Dispatched'),
                                  description: Text('Push notification "$title" sent successfully.'),
                                  type: ToastificationType.success,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                toastification.show(
                                  context: context,
                                  title: const Text('Error Sending Notification'),
                                  description: Text(e.toString()),
                                  type: ToastificationType.error,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(firestoreNotificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Push Notifications (FCM)',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send real-time alerts and manage notification campaign history.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Add Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddNotificationDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Cards & History
            notificationsAsync.when(
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => Expanded(child: Center(child: Text('Error: $err'))),
              data: (allNotifs) {
                final int total = allNotifs.length;
                final int sent = allNotifs.where((n) => n.status.toLowerCase() == 'sent').length;
                final int failed = allNotifs.where((n) => n.status.toLowerCase() == 'failed').length;
                final int pending = allNotifs.where((n) => n.status.toLowerCase() == 'pending').length;

                // Apply Search & Filter
                final q = _searchQuery.trim().toLowerCase();
                final notifs = allNotifs.where((n) {
                  if (q.isNotEmpty) {
                    final titleMatch = n.title.toLowerCase().contains(q);
                    final msgMatch = n.message.toLowerCase().contains(q);
                    final userMatch = n.targetUserName.toLowerCase().contains(q);
                    if (!titleMatch && !msgMatch && !userMatch) return false;
                  }
                  if (_statusFilter != 'All' && n.status.toLowerCase() != _statusFilter.toLowerCase()) {
                    return false;
                  }
                  return true;
                }).toList();

                return Expanded(
                  child: Column(
                    children: [
                      // KPI Row
                      Row(
                        children: [
                          _buildKpiCard('Total Sent', '$total', Icons.campaign_rounded, Colors.blue, isDark),
                          const SizedBox(width: 16),
                          _buildKpiCard('Delivered', '$sent', Icons.check_circle_outline, Colors.green, isDark),
                          const SizedBox(width: 16),
                          _buildKpiCard('Failed', '$failed', Icons.error_outline, Colors.red, isDark),
                          const SizedBox(width: 16),
                          _buildKpiCard('Pending', '$pending', Icons.hourglass_top_rounded, Colors.orange, isDark),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Search Bar & Filter
                      Row(
                        children: [
                          SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search title, message, user...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _statusFilter,
                            underline: const SizedBox(),
                            items: ['All', 'Sent', 'Failed', 'Pending']
                                .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text('Status: $f', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _statusFilter = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // History Data Table
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                          ),
                          child: notifs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted),
                                      const SizedBox(height: 12),
                                      const Text('No Notification History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Click "+ Add Notification" to broadcast your first push message.', style: TextStyle(color: AppColors.textMuted)),
                                    ],
                                  ),
                                )
                              : DataTable2(
                                  columnSpacing: 16,
                                  horizontalMargin: 16,
                                  columns: const [
                                    DataColumn2(label: Text('Title'), size: ColumnSize.M),
                                    DataColumn2(label: Text('Message'), size: ColumnSize.L),
                                    DataColumn2(label: Text('Target Users'), size: ColumnSize.M),
                                    DataColumn2(label: Text('Date & Time'), size: ColumnSize.M),
                                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                                    DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                                  ],
                                  rows: notifs.map((n) {
                                    final isSent = n.status.toLowerCase() == 'sent';
                                    final isFailed = n.status.toLowerCase() == 'failed';

                                    final statusColor = isSent
                                        ? Colors.green
                                        : (isFailed ? Colors.red : Colors.orange);

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                n.targetType.toLowerCase() == 'all' ? Icons.public : Icons.person,
                                                size: 16,
                                                color: AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(n.targetUserName),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(_dateFmt.format(n.createdAt))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              n.status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () async {
                                              await ref.read(notificationRepositoryProvider).deleteNotification(n.id);
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String count, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Card(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
