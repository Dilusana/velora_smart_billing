import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../employee_login_screen.dart';
import 'driver_delivery_detail_screen.dart';

class DriverMetricsScreen extends StatelessWidget {
  final String? driverId;

  const DriverMetricsScreen({
    super.key,
    this.driverId,
  });

  void _handleLogout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDriverId = driverId ?? 'CR-8942';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      body: SafeArea(
        child: StreamBuilder<List<OrderModel>>(
          stream: OrderService.getDeliveryOrdersStream(todayOnly: false),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            final deliveryOrders = orders.where((o) => o.isDelivery).toList();

            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayEnd = todayStart.add(const Duration(days: 1));

            // Completed orders (all historical completed/delivered/collected)
            final completedOrders = deliveryOrders
                .where((o) => o.isDelivered || o.normalizedStatus == 'COMPLETED' || o.normalizedStatus == 'DELIVERED' || o.normalizedStatus == 'COLLECTED')
                .toList();

            // Today's completed orders
            final todayCompletedOrders = completedOrders.where((o) {
              final delDate = o.deliveredAt ?? o.createdAt;
              return (delDate.isAfter(todayStart) && delDate.isBefore(todayEnd)) ||
                  (delDate.year == now.year && delDate.month == now.month && delDate.day == now.day);
            }).toList();

            // Active delivery queue (orders that are currently waiting for delivery or out for delivery, not delivered)
            final inQueueOrders = deliveryOrders
                .where((o) => !o.isDelivered &&
                    (o.normalizedStatus == 'OUT FOR DELIVERY' ||
                     o.normalizedStatus == 'READY' ||
                     o.normalizedStatus == 'COMPLETED' ||
                     o.normalizedStatus == 'ASSIGNED' ||
                     o.normalizedStatus == 'PICKING' ||
                     o.normalizedStatus == 'NEW' ||
                     o.normalizedStatus == 'PROCESSING'))
                .toList();

            // Total revenue from all completed orders
            final totalRevenue = completedOrders.fold<num>(0, (sum, o) => sum + o.total);

            // Today's revenue amount (from orders completed today)
            final todayAmount = todayCompletedOrders.fold<num>(0, (sum, o) => sum + o.total);

            final recentCompleted = completedOrders.take(6).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    color: const Color(0xFFDCFCE7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          'Live Cloud Sync • Connected to Dispatch',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Bar
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Courier Dispatch Portal',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B3E19),
                                ),
                              ),
                            ),
                            const Icon(Icons.notifications_none_rounded, color: Color(0xFF1B3E19), size: 22),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Courier Profile Card
                        Container(
                          padding: const EdgeInsets.all(18),
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC8E635),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Alex Mercer',
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF1B3E19),
                                              ),
                                            ),
                                            Text(
                                              'Driver ID: $currentDriverId',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1B3E19),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFC8E635)),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Active Courier',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Shift Started: 08:00 AM', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280))),
                                        Text('Vehicle: Van (V-401)', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Total Revenue & Today Amount Card (Payout removed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Revenue',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Today: Rs. ${todayAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rs. ${totalRevenue.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1B3E19),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF2E6B2A)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${todayCompletedOrders.length} Completed Today • ${completedOrders.length} Total Delivered',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2E6B2A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid (Completed & In Queue)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
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
                                    Text('Completed', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${completedOrders.length}',
                                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1B3E19)),
                                    ),
                                    Text('Orders Delivered', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
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
                                    Text('Delivery Queue', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${inQueueOrders.length}',
                                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1B3E19)),
                                    ),
                                    Text('Pending Drop-offs', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Order Completed History Section
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
                                      color: const Color(0xFF1B3E19),
                                    ),
                                  ),
                                  Text(
                                    '${completedOrders.length} Records',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2E6B2A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FEE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Order ID',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Customer',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Date',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Amount',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Dynamic Completed Orders Rows
                              if (recentCompleted.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.history_toggle_off_rounded, size: 32, color: Color(0xFF9CA3AF)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No completed delivery orders yet.',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                for (int i = 0; i < recentCompleted.length; i++) ...[
                                  _buildDriverHistoryRow(context, recentCompleted[i]),
                                  if (i < recentCompleted.length - 1)
                                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

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
                              'Logout from Driver Portal',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverHistoryRow(BuildContext context, OrderModel order) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[order.createdAt.month - 1]} ${order.createdAt.day}, ${order.createdAt.year}';
    final idStr = order.displayId.startsWith('#') ? order.displayId : '#${order.displayId}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverDeliveryDetailScreen(
              order: order,
              orderId: order.id,
            ),
          ),
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
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
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
                'Rs. ${order.total}',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
