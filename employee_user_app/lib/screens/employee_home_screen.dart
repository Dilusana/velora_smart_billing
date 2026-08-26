import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'employee_orders_screen.dart';
import 'employee_order_detail_screen.dart';
import 'employee_item_picking_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      body: SafeArea(
        child: StreamBuilder<List<OrderModel>>(
          stream: OrderService.getOrdersStream(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];

            final assignedTodayCount = orders.length;
            final completedCount = orders.where((o) => o.normalizedStatus == 'COMPLETED').length;
            final inProgressCount = orders.where((o) => o.normalizedStatus == 'PICKING' || o.normalizedStatus == 'PACKING' || o.normalizedStatus == 'ASSIGNED').length;
            final urgentCount = orders.where((o) => o.specialInstructions.isNotEmpty || o.normalizedStatus == 'NEW').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Bar ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC8E635), width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Good Morning, Rahul',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👋', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Text(
                              'Monday, 28 Jul • 09:00 – 17:00',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A2D5A), size: 20),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stat Cards Grid (2x2) ───────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('$assignedTodayCount', 'Assigned Today', const Color(0xFF1A2D5A))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('$completedCount', 'Completed', const Color(0xFF1A2D5A))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('$inProgressCount', 'In Progress', const Color(0xFFD97706))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('$urgentCount', 'Urgent', const Color(0xFFDC2626), isUrgent: true)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Critical Alerts Section ──────────────────────────────
                  Text(
                    'Critical Alerts',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2D5A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCriticalAlertCard(
                          accentColor: const Color(0xFFDC2626),
                          icon: Icons.error_rounded,
                          iconColor: const Color(0xFFDC2626),
                          badgeLabel: 'HIGH PRIORITY',
                          title: 'Low Stock Alert',
                          description: 'Aisle 4, Bay 12: Thermal Labels depleted. Restock immediately.',
                          buttonText: 'Acknowledge',
                        ),
                        const SizedBox(width: 12),
                        _buildCriticalAlertCard(
                          accentColor: const Color(0xFFF59E0B),
                          icon: Icons.person_pin_circle_rounded,
                          iconColor: const Color(0xFFD97706),
                          badgeLabel: 'CUSTOMER NOTE',
                          title: 'Order Delay Request',
                          description: 'ORD-8829: Customer requested pickup shift to 14:00.',
                          buttonText: 'Review Note',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── My Orders Today Section ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Orders Today',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2D5A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmployeeOrdersScreen()),
                          );
                        },
                        child: Text(
                          'View All',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (orders.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF6B7280)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No orders yet today. New orders will appear here automatically.',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...orders.take(2).map((order) {
                      final isPrimary = order.normalizedStatus == 'PICKING';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOrderProgressCard(
                          context: context,
                          order: order,
                          isPrimaryAction: isPrimary,
                        ),
                      );
                    }),
                  ],




                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label, Color numberColor, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent ? Border.all(color: const Color(0xFFFEE2E2), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isUrgent ? FontWeight.w800 : FontWeight.w500,
              color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertCard({
    required Color accentColor,
    required IconData icon,
    required Color iconColor,
    required String badgeLabel,
    required String title,
    required String description,
    required String buttonText,
  }) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2D5A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgressCard({
    required BuildContext context,
    required OrderModel order,
    required bool isPrimaryAction,
  }) {
    final pctText = '${(order.progressPercentage * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayId,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                    Text(
                      '${order.primaryCategory} • ${order.totalItemsCount} Items',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                pctText,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                order.normalizedStatus,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: order.progressPercentage,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: const Color(0xFFC8E635),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPrimaryAction ? const Color(0xFFF7FEE7) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.stepProgressText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPrimaryAction ? const Color(0xFF65A30D) : const Color(0xFF6B7280),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: isPrimaryAction
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EmployeeItemPickingScreen(orderId: order.id)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8E635),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
