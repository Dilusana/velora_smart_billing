import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'employee_home_screen.dart';
import 'employee_orders_screen.dart';
import 'employee_alerts_screen.dart';
import 'employee_profile_screen.dart';

class EmployeeMainNavigation extends StatefulWidget {
  final int initialIndex;
  const EmployeeMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<EmployeeMainNavigation> createState() => _EmployeeMainNavigationState();
}

class _EmployeeMainNavigationState extends State<EmployeeMainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    EmployeeHomeScreen(),
    EmployeeOrdersScreen(),
    _ScannerPlaceholderScreen(),
    EmployeeAlertsScreen(),
    EmployeeProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: StreamBuilder<List<OrderModel>>(
        stream: OrderService.getOrdersStream(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final newOrPendingCount = orders
              .where((o) => o.normalizedStatus == 'NEW' || o.normalizedStatus == 'PICKING')
              .length;
          final badgeText = newOrPendingCount > 0 ? '$newOrPendingCount' : null;

          return Container(
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2D5A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.assignment_rounded, 'Orders', badgeCount: badgeText),
                _buildNavItem(3, Icons.notifications_rounded, 'Alerts', badgeCount: '4', badgeColor: const Color(0xFFDC2626)),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {String? badgeCount, Color? badgeColor}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8E635) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF1A2D5A) : const Color(0xFF9CA3AF),
                ),
                if (badgeCount != null && !isSelected)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2D5A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simple scanner placeholder (tab 2 – previously a hardcoded picking screen)
class _ScannerPlaceholderScreen extends StatelessWidget {
  const _ScannerPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Color(0xFF1A2D5A)),
              ),
              const SizedBox(height: 20),
              Text(
                'SKU Scanner',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2D5A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan barcodes to look up products',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
