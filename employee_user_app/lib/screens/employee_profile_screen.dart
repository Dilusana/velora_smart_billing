import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'employee_login_screen.dart';
import 'employee_order_detail_screen.dart';
import 'employee_orders_screen.dart';

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  void _handleLogout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Velora',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2D5A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A2D5A), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2D5A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A2D5A).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8E635), width: 3),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Marcus Chen',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF93C5FD)),
                          const SizedBox(width: 6),
                          Text(
                            'Morning Shift: 06:00 - 14:00',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFFE0F2FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 12, color: Color(0xFF93C5FD)),
                          const SizedBox(width: 6),
                          Text(
                            'Zone A-4 (Electronics)',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFFE0F2FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8E635),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Stream for Stats and Order History
              StreamBuilder<List<OrderModel>>(
                stream: OrderService.getAllOrdersStream(),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  final completedOrders = orders.where((o) => o.normalizedStatus == 'COMPLETED' || o.normalizedStatus == 'DELIVERED').toList();
                  final inProgressOrders = orders.where((o) => o.normalizedStatus != 'COMPLETED' && o.normalizedStatus != 'DELIVERED').toList();

                  final completedCountStr = completedOrders.length < 10 ? '0${completedOrders.length}' : '${completedOrders.length}';
                  final inProgressCountStr = inProgressOrders.length < 10 ? '0${inProgressOrders.length}' : '${inProgressOrders.length}';
                  final recentOrders = orders.take(5).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat Grid (2x2)
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileStatCard(
                              label: 'Completed Today',
                              value: completedCountStr,
                              badgeText: '+${completedOrders.length} total',
                              badgeColor: const Color(0xFF16A34A),
                              badgeBg: const Color(0xFFF7FEE7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProfileStatCard(
                              label: 'In Progress',
                              value: inProgressCountStr,
                              badgeText: inProgressOrders.isNotEmpty ? 'Active' : 'Idle',
                              badgeColor: const Color(0xFF2563EB),
                              badgeBg: const Color(0xFFEFF6FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileStatCard(
                              label: 'Avg Completion',
                              value: '14m',
                              badgeText: 'Standard',
                              badgeColor: const Color(0xFF65A30D),
                              badgeBg: const Color(0xFFF7FEE7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProfileStatCard(
                              label: 'Accuracy Rate',
                              value: '98%',
                              showProgressBar: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Performance Section with Bar Chart & Feedback Quote
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Performance',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                                Text(
                                  'Weekly Bar Chart',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Bar Chart Visualization
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBarColumn('Mon', 0.4),
                                _buildBarColumn('Tue', 0.6),
                                _buildBarColumn('Wed', 0.5),
                                _buildBarColumn('Today', 0.95, isCurrent: true, valueText: '${orders.length}'),
                                _buildBarColumn('Fri', 0.2),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Quote Feedback Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '"Excellent picking speed today! You\'re performing above the facility average."',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF374151),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Order History Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order History',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const EmployeeOrdersScreen()),
                                    );
                                  },
                                  child: Text(
                                    'View All Records',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // History Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text('Order ID', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A)))),
                                  Expanded(flex: 3, child: Text('Customer', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A)))),
                                  Expanded(flex: 2, child: Text('Date', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A)))),
                                  Expanded(flex: 2, child: Text('Time', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A)), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Dynamic History Rows from Firestore
                            if (recentOrders.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No order history records found.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (int i = 0; i < recentOrders.length; i++) ...[
                                _buildDynamicHistoryRow(context, recentOrders[i]),
                                if (i < recentOrders.length - 1)
                                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Employment Details Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employment Details',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Attendance Status', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF65A30D), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Clocked In', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF65A30D))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Contact Info', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Text('m.chen@velora-logistics.com', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Direct Supervisor', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        const Spacer(),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Sarah Jenkins', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Support & Resources Section
              Text(
                'Support & Resources',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2D5A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.import_contacts_rounded, size: 20, color: Color(0xFF1A2D5A)),
                          const SizedBox(width: 8),
                          Text('Training Hub', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.headset_mic_outlined, size: 20, color: Color(0xFF1A2D5A)),
                          const SizedBox(width: 8),
                          Text('IT Support', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                  label: Text(
                    'Logout from Device',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard({
    required String label,
    required String value,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    bool showProgressBar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A2D5A),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg ?? Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (showProgressBar) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.96,
                minHeight: 4,
                backgroundColor: Color(0xFFE5E7EB),
                color: Color(0xFF65A30D),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarColumn(String dayLabel, double fillRatio, {bool isCurrent = false, String? valueText}) {
    return Column(
      children: [
        if (valueText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2D5A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              valueText,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
        else
          const SizedBox(height: 18),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 70,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            heightFactor: fillRatio,
            child: Container(
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF1A2D5A) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dayLabel,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            color: isCurrent ? const Color(0xFF1A2D5A) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicHistoryRow(BuildContext context, OrderModel order) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[order.createdAt.month - 1]} ${order.createdAt.day}, ${order.createdAt.year}';
    final idStr = order.displayId.startsWith('#') ? order.displayId : '#${order.displayId}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                idStr,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                order.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF374151)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.createdTimeFormatted,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
