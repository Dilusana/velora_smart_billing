import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'employee_order_detail_screen.dart';
import 'employee_item_picking_screen.dart';
import 'employee_workflow_tracking_screen.dart';
import 'employee_alerts_screen.dart';

class EmployeeOrdersScreen extends StatefulWidget {
  const EmployeeOrdersScreen({super.key});

  @override
  State<EmployeeOrdersScreen> createState() => _EmployeeOrdersScreenState();
}

class _EmployeeOrdersScreenState extends State<EmployeeOrdersScreen> {
  int _selectedTab = 0; // 0 = Active Queue, 1 = Order History

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateString = 'Today, ${now.day} ${months[now.month - 1]}';

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
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmployeeAlertsScreen(showBackButton: true)),
                      );
                    },
                    child: Container(
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
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title & Filter Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Orders',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              dateString,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Tab Filter (Active Queue vs Order History)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? const Color(0xFF1A2D5A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Active Queue',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 0 ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? const Color(0xFF1A2D5A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Order History',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 1 ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Real-Time Stream from Firestore
              StreamBuilder<List<OrderModel>>(
                stream: OrderService.getOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF1A2D5A)),
                      ),
                    );
                  }

                  final allOrders = snapshot.data ?? [];

                  // 0 = Active Queue (exclude collected / delivered), 1 = History (collected / delivered)
                  final displayedOrders = _selectedTab == 0
                      ? allOrders.where((o) => o.normalizedStatus != 'DELIVERED' && o.normalizedStatus != 'COLLECTED').toList()
                      : allOrders.where((o) => o.normalizedStatus == 'DELIVERED' || o.normalizedStatus == 'COLLECTED').toList();

                  if (displayedOrders.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _selectedTab == 0 ? Icons.inbox_outlined : Icons.history_rounded,
                              size: 40,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0 ? 'No Active Orders' : 'No History Yet',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A2D5A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedTab == 0
                                ? 'All orders for today have been collected or delivered.'
                                : 'Collected and delivered orders will appear here in history.',
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

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedOrders.length,
                    separatorBuilder: (context, idx) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _buildDynamicOrderCard(context, order);
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicOrderCard(BuildContext context, OrderModel order) {
    final statusNorm = order.normalizedStatus;

    Color badgeBg;
    Color badgeTextColor;
    String buttonText;
    Color buttonBgColor;
    Color buttonTextColor;
    bool hasBorderGlow = false;
    bool hasPlayIcon = false;
    bool hasCheckBadge = false;
    String? countBadgeText;
    VoidCallback onTap;

    if (statusNorm == 'NEW') {
      badgeBg = const Color(0xFFEFF8C6);
      badgeTextColor = const Color(0xFF65A30D);
      hasBorderGlow = true;
      buttonText = 'Accept Order';
      buttonBgColor = const Color(0xFFC8E635);
      buttonTextColor = const Color(0xFF1A2D5A);
      onTap = () async {
        await OrderService.updateOrderStatus(order.id, 'Picking');
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
          );
        }
      };
    } else if (statusNorm == 'PICKING') {
      badgeBg = const Color(0xFFDBEAFE);
      badgeTextColor = const Color(0xFF2563EB);
      countBadgeText = '${order.pickedItemsCount}/${order.totalItemsCount}';
      buttonText = 'Continue Working';
      buttonBgColor = const Color(0xFF1A2D5A);
      buttonTextColor = Colors.white;
      hasPlayIcon = true;
      onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeItemPickingScreen(orderId: order.id)),
        );
      };
    } else if (statusNorm == 'READY') {
      badgeBg = const Color(0xFFE0E7FF);
      badgeTextColor = const Color(0xFF4338CA);
      hasCheckBadge = true;
      buttonText = 'Track Workflow';
      buttonBgColor = const Color(0xFFDBEAFE);
      buttonTextColor = const Color(0xFF1E40AF);
      onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeWorkflowTrackingScreen(orderId: order.displayId)),
        );
      };
    } else if (statusNorm == 'COLLECTED' || statusNorm == 'DELIVERED') {
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
      hasCheckBadge = true;
      buttonText = 'View Summary';
      buttonBgColor = const Color(0xFF1A2D5A);
      buttonTextColor = Colors.white;
      onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
        );
      };
    } else {
      badgeBg = const Color(0xFFEFF8C6);
      badgeTextColor = const Color(0xFF65A30D);
      buttonText = 'View Details';
      buttonBgColor = const Color(0xFF1A2D5A);
      buttonTextColor = Colors.white;
      onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
        );
      };
    }

    final firstItemName = order.items.isNotEmpty ? order.items.first.productName : 'General Order';
    final productSubtitle = '${order.primaryCategory} • ${order.totalItemsCount} ${order.totalItemsCount == 1 ? 'item' : 'items'}';
    final firstImageUrl = order.items.isNotEmpty ? order.items.first.imageUrl : '';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmployeeOrderDetailScreen(orderId: order.id)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: hasBorderGlow ? Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
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
                  order.displayId,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusNorm,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Assigned ${order.timeAgoFormatted} • ${order.createdTimeFormatted}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: firstImageUrl.isNotEmpty
                        ? Image.network(
                            firstImageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFE5E7EB),
                              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6B7280)),
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6B7280)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                        Text(
                          productSubtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (countBadgeText != null)
                    Text(
                      countBadgeText,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                  if (hasCheckBadge)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFBEF264),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF1A2D5A)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    final isFilled = index < order.stepProgressDots;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isFilled ? const Color(0xFF1A2D5A) : const Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  order.stepProgressText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (order.normalizedStatus == 'COMPLETED' || order.normalizedStatus == 'READY') ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text('Customer Collected Order?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                              content: Text('Mark ${order.displayId} as collected by customer? It will be removed from the active queue and moved to history.', style: GoogleFonts.outfit(fontSize: 13)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6B7280))),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: Text('Confirm Collected', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await OrderService.updateOrderStatus(order.id, 'Collected');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${order.displayId} marked as collected and moved to history!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Mark Collected',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasPlayIcon) ...[
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        buttonText,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: buttonTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
