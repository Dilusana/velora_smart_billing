import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/driver_auth_service.dart';
import '../../services/order_service.dart';
import 'driver_delivery_detail_screen.dart';
import 'driver_map_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final String? driverId;

  const DriverHomeScreen({super.key, this.driverId});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final Set<String> _deliveringOrderIds = {};

  String _formatTodayDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    return '$dayName, ${d.day} $monthName ${d.year}';
  }

  Future<void> _handlePickToDeliver(BuildContext context, OrderModel order) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeDriverId = widget.driverId ?? DriverAuthService.instance.driverId;
    final activeDriverName = DriverAuthService.instance.driverName;

    setState(() {
      _deliveringOrderIds.add(order.id);
    });

    // Update status to Out for Delivery in Firestore and assign driver
    await OrderService.updateOrderStatus(order.id, 'Out for Delivery');
    await OrderService.assignOrderToDriver(
      docId: order.id,
      driverId: activeDriverId,
      driverName: activeDriverName,
    );

    if (mounted) {
      setState(() {
        _deliveringOrderIds.remove(order.id);
      });

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B3E19),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: Color(0xFFC8E635), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order ${order.displayId} picked for delivery! Opening GPS Navigation.',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

      // Open Map View
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DriverMapScreen(order: order),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DriverAuthService.instance,
      builder: (context, _) {
        final activeDriverId = widget.driverId ?? DriverAuthService.instance.driverId;
        final driverName = DriverAuthService.instance.driverName;
        final hubName = DriverAuthService.instance.hubName;
        final vehicleInfo = DriverAuthService.instance.vehicleInfo;
        final isOnline = DriverAuthService.instance.isOnline;

        final now = DateTime.now();
        final formattedDate = _formatTodayDate(now);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F8F3),
          body: SafeArea(
            child: StreamBuilder<List<OrderModel>>(
              stream: OrderService.getDriverTodayOrdersStream(
                driverId: activeDriverId,
                date: now,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B3E19)),
                  );
                }

                final allTodayOrders = snapshot.data ?? [];
                // Active queue: Today's assigned orders that still require delivery
                final deliveryQueue = allTodayOrders.where((o) => !o.isDelivered).toList();
                // Delivered section: Orders delivered today
                final deliveredOrders = allTodayOrders.where((o) => o.isDelivered).toList();

                final totalToday = allTodayOrders.length;
                final queueCount = deliveryQueue.length;
                final deliveredCount = deliveredOrders.length;
                final completionRate = totalToday > 0 ? (deliveredCount / totalToday) : 0.0;

                return Stack(
                  children: [
                    RefreshIndicator(
                      color: const Color(0xFF1B3E19),
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. DRIVER INFORMATION & GREETING BAR
                            _buildDriverHeader(
                              driverName: driverName,
                              driverId: activeDriverId,
                              hubName: hubName,
                              vehicleInfo: vehicleInfo,
                              isOnline: isOnline,
                              formattedDate: formattedDate,
                            ),
                            const SizedBox(height: 18),

                            // 2. TODAY'S DELIVERIES SUMMARY / KPI DASHBOARD
                            _buildTodaySummaryCard(
                              totalToday: totalToday,
                              queueCount: queueCount,
                              deliveredCount: deliveredCount,
                              completionRate: completionRate,
                            ),
                            const SizedBox(height: 24),

                            // 3. SECTION: DELIVERY QUEUE (ACTIVE ORDERS)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Delivery Queue',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF1B3E19),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: queueCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$queueCount',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: queueCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (queueCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF8C6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF65A30D)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Action Required',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF65A30D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (deliveryQueue.isEmpty) ...[
                              _buildEmptyQueueCard(totalToday: totalToday, deliveredCount: deliveredCount),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: deliveryQueue.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final order = deliveryQueue[index];
                                  final isProcessingThis = _deliveringOrderIds.contains(order.id);
                                  return _buildActiveQueueOrderCard(
                                    context: context,
                                    order: order,
                                    index: index + 1,
                                    isProcessingThis: isProcessingThis,
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 32),

                            // 4. SECTION: DELIVERED ORDERS (COMPLETED TODAY)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Delivered Orders',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF16A34A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$deliveredCount',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (deliveredCount > 0)
                                  Text(
                                    'COMPLETED',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16A34A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (deliveredOrders.isEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Center(
                                  child: Text(
                                    'No completed deliveries yet today. Orders will appear here once delivered.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: deliveredOrders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = deliveredOrders[index];
                                  return _buildDeliveredOrderCard(context, order);
                                },
                              ),
                            ],

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),

                    // Floating SOS Emergency Button
                    Positioned(
                      right: 18,
                      bottom: 18,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFC81E1E),
                              content: Text('SOS Emergency Alert Dispatched to Dispatch Manager!'),
                            ),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC81E1E),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC81E1E).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'SOS',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 1. DRIVER HEADER & GREETING
  Widget _buildDriverHeader({
    required String driverName,
    required String driverId,
    required String hubName,
    required String vehicleInfo,
    required bool isOnline,
    required String formattedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3E19),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3E19).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E635), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: $driverId',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC8E635),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hubName,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF2E6B2A) : const Color(0xFF4B5563),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOnline ? const Color(0xFFC8E635) : Colors.transparent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFC8E635) : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF2D572B)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.directions_car_filled_outlined, size: 13, color: Color(0xFFC8E635)),
                  const SizedBox(width: 4),
                  Text(
                    vehicleInfo,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC8E635),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. TODAY'S DELIVERIES SUMMARY / KPI CARD
  Widget _buildTodaySummaryCard({
    required int totalToday,
    required int queueCount,
    required int deliveredCount,
    required double completionRate,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Deliveries",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B3E19),
                ),
              ),
              Text(
                '${(completionRate * 100).toInt()}% Done',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'Assigned Today',
                  value: '$totalToday',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF1B3E19),
                  bgColor: const Color(0xFFF9F8F3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'In Queue',
                  value: '$queueCount',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'Delivered',
                  value: '$deliveredCount',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 3. EMPTY QUEUE CARD
  Widget _buildEmptyQueueCard({required int totalToday, required int deliveredCount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: deliveredCount > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              deliveredCount > 0 ? Icons.done_all_rounded : Icons.inbox_outlined,
              size: 36,
              color: deliveredCount > 0 ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            deliveredCount > 0 && totalToday == deliveredCount
                ? 'All Deliveries Completed!'
                : 'No Orders in Delivery Queue',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B3E19),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deliveredCount > 0 && totalToday == deliveredCount
                ? 'Great job! You have delivered all $deliveredCount assigned deliveries for today.'
                : 'Only orders assigned to your driver ID for today will appear in your queue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 4. ACTIVE DELIVERY QUEUE CARD
  Widget _buildActiveQueueOrderCard({
    required BuildContext context,
    required OrderModel order,
    required int index,
    required bool isProcessingThis,
  }) {
    Color statusBg = const Color(0xFFEFF8C6);
    Color statusColor = const Color(0xFF65A30D);
    final normStatus = order.normalizedStatus;
    
    // Check if order is still in store preparation / processing
    final bool isStillProcessing = normStatus == 'PROCESSING' ||
        normStatus == 'NEW' ||
        normStatus == 'PICKING';

    if (normStatus == 'PICKING') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
    } else if (normStatus == 'READY' || normStatus == 'COMPLETED') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF16A34A);
    } else if (normStatus == 'OUT FOR DELIVERY') {
      statusBg = const Color(0xFFDBEAFE);
      statusColor = const Color(0xFF2563EB);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B3E19),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  order.displayId,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B3E19),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.normalizedStatus,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Information
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF1B3E19)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B3E19),
                        ),
                      ),
                    ),
                    if (order.customerPhone.isNotEmpty)
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling customer: ${order.customerPhone}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                'Call',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order Details Pill Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF4B5563)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.totalItemsCount} ${order.totalItemsCount == 1 ? 'Item' : 'Items'} • ${order.primaryCategory}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      Text(
                        'Rs. ${order.total}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B3E19),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ACTION BUTTONS ROW
                Row(
                  children: [
                    // Navigate / View Details Button
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DriverMapScreen(order: order),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B3E19),
                            side: const BorderSide(color: Color(0xFF1B3E19), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(
                            'Navigate',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // "PICK TO DELIVER" PRIMARY ACTION BUTTON
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: (isStillProcessing || isProcessingThis)
                              ? null
                              : () => _handlePickToDeliver(context, order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: isProcessingThis
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  isStillProcessing ? Icons.hourglass_empty_rounded : Icons.local_shipping_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            isProcessingThis
                                ? 'Picking...'
                                : (isStillProcessing ? 'Pick to Deliver' : 'Pick to Deliver'),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. DELIVERED ORDER CARD (COMPLETED)
  Widget _buildDeliveredOrderCard(BuildContext context, OrderModel order) {
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.displayId,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B3E19),
                        ),
                      ),
                      Text(
                        'Rs. ${order.total}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B3E19),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customerName} • ${order.deliveryAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Delivered: ${order.deliveredTimeFormatted}',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${order.totalItemsCount} items',
                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
