import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driver_home_screen.dart';
import 'driver_map_screen.dart';
import 'driver_metrics_screen.dart';

class DriverMainNavigation extends StatefulWidget {
  final int initialIndex;
  final String? driverId;

  const DriverMainNavigation({
    super.key,
    this.initialIndex = 0,
    this.driverId,
  });

  @override
  State<DriverMainNavigation> createState() => _DriverMainNavigationState();
}

class _DriverMainNavigationState extends State<DriverMainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _screens => [
    DriverHomeScreen(driverId: widget.driverId),
    const DriverMapScreen(),
    DriverMetricsScreen(driverId: widget.driverId),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFF1B3E19),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDriverNavItem(0, Icons.local_shipping_rounded, 'Today'),
            _buildDriverNavItem(1, Icons.explore_rounded, 'Map'),
            _buildDriverNavItem(2, Icons.bar_chart_rounded, 'Metrics'),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8E635) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF1B3E19) : const Color(0xFF9CA3AF),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B3E19),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
