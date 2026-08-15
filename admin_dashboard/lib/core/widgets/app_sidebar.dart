import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'main_layout.dart'; // To access the sidebarExpandedProvider
import '../../providers/app_providers.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final width = isExpanded ? 310.0 : 72.0;
    
    // In a real app, use GoRouterState.of(context).uri.path
    // Wrapping with a safe check for development.
    String currentPath = '/dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo Block
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 0),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Velora',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Enterprise Admin',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  path: '/dashboard',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  path: '/products',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  path: '/categories',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.warehouse_rounded,
                  label: 'Inventory',
                  path: '/inventory',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  path: '/orders',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sales',
                  path: '/sales',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Customers',
                  path: '/customers',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.payment_rounded,
                  label: 'Payments',
                  path: '/payments',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Suppliers',
                  path: '/suppliers',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  path: '/reports',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.local_offer_rounded,
                  label: 'Promotions',
                  path: '/promotions',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.badge_rounded,
                  label: 'Employees',
                  path: '/employees',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
                ),
                _NavItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help Center',
                  path: '/help-center',
                  currentPath: currentPath,
                  isExpanded: isExpanded,
                ),
                // Logout Item
                InkWell(
                  onTap: () => _handleLogout(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 16.0 : 0.0,
                      vertical: 12.0,
                    ),
                    alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
                    child: Row(
                      mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.statusRed,
                          size: 24,
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 16),
                          Text(
                            'Logout',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.statusRed,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool isExpanded;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.isExpanded,
  });

  @override
  ConsumerState<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends ConsumerState<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentPath.startsWith(widget.path);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go(widget.path),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 16.0 : 0.0,
            vertical: 12.0,
          ),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.primaryLight 
                : (_isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: widget.isExpanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                size: 24,
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
