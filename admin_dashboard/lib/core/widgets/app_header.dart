import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'main_layout.dart';
import '../../providers/app_providers.dart';

class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final OverlayPortalController _searchOverlayController = OverlayPortalController();
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty && !_searchOverlayController.isShowing) {
        _searchOverlayController.show();
      } else if (_searchController.text.isEmpty && _searchOverlayController.isShowing) {
        _searchOverlayController.hide();
      }
      setState(() {});
    });
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus && _searchOverlayController.isShowing) {
        // slight delay to allow clicks on overlay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _searchOverlayController.hide();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final theme = Theme.of(context);
    final effectiveBrightness = _isDarkMode ? Brightness.dark : theme.brightness;
    final isDark = effectiveBrightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.bgDarkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar Toggle
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            onPressed: () {
              ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
            },
          ),
          const SizedBox(width: 16),
          // Search Bar
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: OverlayPortal(
                  controller: _searchOverlayController,
                  overlayChildBuilder: (context) {
                    return Positioned(
                      top: 56, // below header
                      left: isExpanded ? 310 + 60.0 : 72 + 60.0, // rough position estimation based on layout
                      width: 380,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? AppColors.bgDarkSurface : AppColors.bgCard,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.bgDarkBorder : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSearchResultCategory('Products'),
                              _buildSearchResultItem(Icons.inventory_2, 'MacBook Pro 16"'),
                              _buildSearchResultItem(Icons.inventory_2, 'Wireless Keyboard'),
                              const Divider(),
                              _buildSearchResultCategory('Customers'),
                              _buildSearchResultItem(Icons.person, 'Acme Corp'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search products, orders...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: isDark ? AppColors.bgDarkSurface : AppColors.bgPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Right cluster
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    icon: Badge(
                      label: const Text('3'),
                      backgroundColor: AppColors.statusRed,
                      child: const Icon(Icons.notifications_rounded),
                    ),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                menuChildren: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Notifications', style: AppTextStyles.titleMedium),
                  ),
                  MenuItemButton(child: Text('New order #1024 placed')),
                  MenuItemButton(child: Text('Inventory low for "AirPods"')),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.mail_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: _toggleTheme,
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                width: 1,
                color: isDark ? AppColors.bgDarkBorder : AppColors.border,
              ),
              const SizedBox(width: 16),
              
              // User Menu
              MenuAnchor(
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            'AD',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Super Admin',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.person_rounded),
                    child: const Text('Profile'),
                    onPressed: () {},
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.settings_rounded),
                    child: const Text('Account Settings'),
                    onPressed: () {},
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.logout_rounded, color: AppColors.statusRed),
                    child: const Text('Logout', style: TextStyle(color: AppColors.statusRed)),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchResultCategory(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(IconData icon, String text) {
    return InkWell(
      onTap: () {
        _searchOverlayController.hide();
        _searchController.clear();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(text, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
