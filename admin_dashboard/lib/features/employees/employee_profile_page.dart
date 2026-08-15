import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import '../../core/theme/app_theme.dart';

class EmployeeProfilePage extends ConsumerStatefulWidget {
  final String id;
  const EmployeeProfilePage({super.key, required this.id});

  @override
  ConsumerState<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _modules = [
    'Dashboard', 'Products', 'Categories', 'Inventory',
    'Orders', 'Customers', 'Payments', 'Suppliers',
    'Reports', 'Promotions', 'Employees'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                const Text('Employee Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
                  onPressed: () {},
                  child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 40, child: Text('AJ', style: TextStyle(fontSize: 24))),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alice Johnson', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Chip(label: const Text('Manager'), backgroundColor: AppColors.primary.withOpacity(0.1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Permissions Matrix'),
                Tab(text: 'Activity Log'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const Center(child: Text('Overview Content')),
                  _buildPermissionsMatrix(isDark),
                  const Center(child: Text('Activity Log Content')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsMatrix(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              return CheckboxListTile(
                title: Text(_modules[index]),
                value: true,
                onChanged: (val) {},
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            toastification.show(
              context: context,
              title: const Text('Permissions Saved'),
              type: ToastificationType.success,
            );
          },
          child: const Text('Save Permissions', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
