import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'employee_item_picking_screen.dart';

class EmployeeOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const EmployeeOrderDetailScreen({
    super.key,
    this.orderId = 'order_1787462193108',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: OrderService.getOrderByIdStream(orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && order == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F5EE),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1A2D5A)),
            ),
          );
        }

        final displayOrder = order ??
            OrderModel(
              id: orderId,
              branch: 'Main Branch',
              createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
              customerId: 'cust_01',
              customerName: 'dilu',
              customerPhone: '0775904043',
              deliveryAddress: 'Store Pickup (Main Branch)',
              deliveryFee: 0,
              discount: 0,
              items: [],
              orderSource: 'UserApp',
              paymentMethod: 'Paid via UPI',
              paymentStatus: 'Paid',
              status: 'New',
              subtotal: 1500,
              total: 1500,
              users: 'dilu',
              assignedEmployeeName: 'Rahul A.',
              specialInstructions: 'Customer requested paper bags only. Fragile glassware included in the order. Handle with care.',
            );

        final statusNorm = displayOrder.normalizedStatus;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F5EE),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F5EE),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2D5A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Text(
                  'Order ${displayOrder.displayId}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8C6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusNorm,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF65A30D),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: Color(0xFF1A2D5A), size: 20),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currently Assigned Card
                  Container(
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
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8E635),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
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
                                'CURRENTLY ASSIGNED',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                displayOrder.assignedEmployeeName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A2D5A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ASSIGNED AT', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF9CA3AF))),
                                      Text('${displayOrder.createdTimeFormatted} Today', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TIME ELAPSED', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF9CA3AF))),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFDC2626)),
                                          const SizedBox(width: 3),
                                          Text(
                                            displayOrder.timeAgoFormatted,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF1A2D5A)),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Information',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Order ID & Customer Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORDER ID',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    displayOrder.id,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A2D5A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CUSTOMER NAME',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayOrder.customerName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A2D5A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PHONE NUMBER',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayOrder.customerPhone.isNotEmpty ? displayOrder.customerPhone : 'Not Provided',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: displayOrder.customerPhone.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'PAYMENT METHOD',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF374151)),
                            const SizedBox(width: 8),
                            Text(
                              displayOrder.paymentMethod,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: displayOrder.paymentStatus.toLowerCase() == 'paid'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF9C3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayOrder.paymentStatus,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: displayOrder.paymentStatus.toLowerCase() == 'paid'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFA16207),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'DELIVERY / PICKUP LOCATION',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, size: 18, color: Color(0xFF65A30D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayOrder.deliveryAddress,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF65A30D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Special Instructions Warning Box
                        if (displayOrder.specialInstructions.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEFCE8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFDE047)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SPECIAL INSTRUCTIONS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFB45309),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayOrder.specialInstructions,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF78350F),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Items Card
                  if (displayOrder.items.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF1A2D5A)),
                              const SizedBox(width: 8),
                              Text(
                                'Order Items',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A2D5A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${displayOrder.totalItemsCount} ${displayOrder.totalItemsCount == 1 ? 'item' : 'items'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...displayOrder.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF), size: 20),
                                          ),
                                        )
                                      : Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF), size: 20),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A2D5A),
                                        ),
                                      ),
                                      Text(
                                        '${item.category} • Rs ${item.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Rs ${item.total.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A2D5A),
                                ),
                              ),
                              Text(
                                'Rs ${displayOrder.total.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A2D5A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Order Status Card (Dark Navy)
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
                    child: Builder(
                      builder: (context) {
                        final isAllPicked = displayOrder.totalItemsCount > 0 &&
                            displayOrder.pickedItemsCount == displayOrder.totalItemsCount;
                        final isPickingDone = isAllPicked ||
                            statusNorm == 'PACKING' ||
                            statusNorm == 'READY' ||
                            statusNorm == 'COMPLETED' ||
                            statusNorm == 'DELIVERED' ||
                            statusNorm == 'OUT FOR DELIVERY';
                        final isPackingDone = isAllPicked ||
                            statusNorm == 'READY' ||
                            statusNorm == 'COMPLETED' ||
                            statusNorm == 'DELIVERED' ||
                            statusNorm == 'OUT FOR DELIVERY';
                        final isReadyDone = isAllPicked ||
                            statusNorm == 'READY' ||
                            statusNorm == 'COMPLETED' ||
                            statusNorm == 'DELIVERED' ||
                            statusNorm == 'OUT FOR DELIVERY';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Status',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC8E635),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Timeline Step 1 - Placed
                            _buildTimelineStep(
                              title: 'Order Placed',
                              subtitle: displayOrder.createdTimeFormatted,
                              isCompleted: true,
                              isLast: false,
                            ),
                            // Timeline Step 2 - Assigned
                            _buildTimelineStep(
                              title: 'Employee Assigned',
                              subtitle: displayOrder.createdTimeFormatted,
                              isCompleted: true,
                              isLast: false,
                            ),
                            // Timeline Step 3 - Items Picking
                            _buildTimelineStep(
                              title: 'Items Picking',
                              subtitle: isPickingDone
                                  ? 'Completed'
                                  : (statusNorm == 'PICKING' ? 'In Progress' : 'Pending'),
                              isActive: statusNorm == 'PICKING' && !isPickingDone,
                              isCompleted: isPickingDone,
                              isLast: false,
                            ),
                            // Timeline Step 4 - Packing
                            _buildTimelineStep(
                              title: 'Packing',
                              subtitle: isPackingDone
                                  ? 'Completed'
                                  : (statusNorm == 'PACKING' ? 'In Progress' : 'Pending'),
                              isActive: statusNorm == 'PACKING' && !isPackingDone,
                              isCompleted: isPackingDone,
                              isPending: !isPackingDone && statusNorm != 'PACKING',
                              isLast: false,
                              icon: Icons.inventory_2_outlined,
                            ),
                            // Timeline Step 5 - Ready for Pickup / Delivery
                            _buildTimelineStep(
                              title: displayOrder.isDelivery ? 'Ready for Delivery' : 'Ready for Pickup',
                              subtitle: isReadyDone
                                  ? (statusNorm == 'COMPLETED' || statusNorm == 'DELIVERED' ? 'Completed' : 'Ready')
                                  : 'Pending',
                              isCompleted: isReadyDone,
                              isActive: statusNorm == 'READY' && !isReadyDone,
                              isPending: !isReadyDone,
                              isLast: true,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  Builder(
                    builder: (context) {
                      final isAllPicked = displayOrder.totalItemsCount > 0 &&
                          displayOrder.pickedItemsCount == displayOrder.totalItemsCount;
                      final isCompletedOrder = isAllPicked ||
                          statusNorm == 'COMPLETED' ||
                          statusNorm == 'READY';
                      final isAlreadyCollectedOrDelivered = statusNorm == 'COLLECTED' || statusNorm == 'DELIVERED';

                      if (isAlreadyCollectedOrDelivered) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                statusNorm == 'COLLECTED' ? 'Order Collected by Customer' : 'Order Delivered to Customer',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          if (isCompletedOrder) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Customer Collected Order?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                                      content: Text('Mark ${displayOrder.displayId} as collected by customer? It will be removed from the active queue and moved to history.', style: GoogleFonts.outfit(fontSize: 13)),
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
                                    await OrderService.updateOrderStatus(displayOrder.id, 'Collected');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✅ ${displayOrder.displayId} marked as collected and moved to history!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                                          backgroundColor: const Color(0xFF16A34A),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                label: Text(
                                  'Mark as Collected by Customer',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (statusNorm == 'NEW' || statusNorm == 'ASSIGNED') {
                                  await OrderService.updateOrderStatus(displayOrder.id, 'Picking');
                                }
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EmployeeItemPickingScreen(orderId: displayOrder.id),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompletedOrder ? const Color(0xFFEFF8C6) : const Color(0xFFC8E635),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isCompletedOrder) ...[
                                    const Icon(Icons.list_alt_rounded, color: Color(0xFF1A2D5A), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View Picked Items',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A2D5A),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      statusNorm == 'NEW'
                                          ? 'Accept & Start Picking'
                                          : (statusNorm == 'PICKING'
                                              ? 'Continue Picking Items (${displayOrder.pickedItemsCount}/${displayOrder.totalItemsCount})'
                                              : 'Start Picking Items'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A2D5A),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isActive = false,
    bool isPending = false,
    bool isLast = false,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (isCompleted)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8E635),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1A2D5A)),
              )
            else if (isActive)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E635).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E635), width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8E635),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.circle_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isCompleted
                    ? const Color(0xFFC8E635).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCompleted || isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isActive
                    ? const Color(0xFFC8E635)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
