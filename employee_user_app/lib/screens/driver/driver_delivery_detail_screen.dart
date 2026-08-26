import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class DriverDeliveryDetailScreen extends StatefulWidget {
  final OrderModel? order;
  final String orderId;

  const DriverDeliveryDetailScreen({
    super.key,
    this.order,
    required this.orderId,
  });

  @override
  State<DriverDeliveryDetailScreen> createState() => _DriverDeliveryDetailScreenState();
}

class _DriverDeliveryDetailScreenState extends State<DriverDeliveryDetailScreen> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    if (widget.order != null) {
      return StreamBuilder<OrderModel?>(
        stream: OrderService.getOrderByIdStream(widget.order!.id),
        initialData: widget.order,
        builder: (context, snapshot) {
          final liveOrder = snapshot.data ?? widget.order!;
          return _buildContent(context, liveOrder);
        },
      );
    }

    return StreamBuilder<OrderModel?>(
      stream: OrderService.getOrderByIdStream(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(context, snapshot.data!);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9F8F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F8F3),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B3E19)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Text(
              'Delivery Details',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B3E19),
              ),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B3E19)),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, OrderModel order) {
    // An order is delivered if its Firestore status is DELIVERED or completed in this session
    final isOrderDelivered = order.isDelivered || _isCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B3E19)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Delivery Details',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B3E19),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _buildSwipeToCompleteWidget(order, isOrderDelivered),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Order Info Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayId,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B3E19),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Delivering to ${order.customerName}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOrderDelivered ? const Color(0xFFDCFCE7) : const Color(0xFFF7FEE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOrderDelivered ? Icons.check_circle_outline_rounded : Icons.local_shipping_outlined,
                                size: 14,
                                color: isOrderDelivered ? const Color(0xFF16A34A) : const Color(0xFF65A30D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOrderDelivered ? 'Delivered' : order.normalizedStatus,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isOrderDelivered ? const Color(0xFF16A34A) : const Color(0xFF65A30D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer & Address Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC8E635),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF1B3E19), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B3E19),
                                ),
                              ),
                              Text(
                                order.customerPhone.isNotEmpty ? order.customerPhone : 'No phone provided',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (order.customerPhone.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling customer: ${order.customerPhone}')),
                              );
                            },
                            icon: const Icon(Icons.phone_outlined, color: Color(0xFF1B3E19)),
                          ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Timeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Timeline',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B3E19),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineRow(
                      title: 'Order Placed',
                      subtitle: 'Confirmed in branch dispatch system.',
                      time: order.createdTimeFormatted,
                      isCompleted: true,
                    ),
                    _buildTimelineRow(
                      title: 'Items Packed & Ready',
                      subtitle: 'Order prepared for delivery.',
                      time: order.timeAgoFormatted,
                      isCompleted: true,
                    ),
                    _buildTimelineRow(
                      title: isOrderDelivered ? 'Order Delivered' : 'Out for Delivery',
                      subtitle: isOrderDelivered ? 'Delivered to customer address.' : 'En route to ${order.deliveryAddress}.',
                      time: 'Now',
                      isActive: !isOrderDelivered,
                      isCompleted: isOrderDelivered,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Order Items Header & List
              Text(
                'Order Items (${order.totalItemsCount})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B3E19),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF374151), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B3E19),
                                  ),
                                ),
                                Text(
                                  'Price: Rs. ${item.price} • Total: Rs. ${item.total}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.quantity}x',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1B3E19),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Payment & Total Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280))),
                        Text('Rs. ${order.subtotal}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B3E19))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280))),
                        Text('Rs. ${order.deliveryFee}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B3E19))),
                      ],
                    ),
                    if (order.discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF16A34A))),
                          Text('-Rs. ${order.discount}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                        ],
                      ),
                    ],
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1B3E19))),
                        Text('Rs. ${order.total}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1B3E19))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // SWIPE / SCROLL TO COMPLETE DELIVERY WIDGET
  Widget _buildSwipeToCompleteWidget(OrderModel order, bool isOrderDelivered) {
    if (isOrderDelivered) {
      return Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
              const SizedBox(width: 8),
              Text(
                '✓ Delivery Completed!',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        const double buttonSize = 54.0;
        final double maxDrag = (trackWidth - buttonSize - 4).clamp(0.0, double.infinity);

        return Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1B3E19),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3E19).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Active progress fill background behind thumb
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + buttonSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),

              // Animated Slide Hint Text
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSubmitting ? 'Updating Status...' : 'Slide to Complete Delivery',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_double_arrow_right_rounded, color: Color(0xFFC8E635), size: 18),
                  ],
                ),
              ),

              // Draggable Swipe Thumb Handle
              Positioned(
                left: _dragPosition + 2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (!_isCompleted && !_isSubmitting) {
                        setState(() {
                          _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                        });
                      }
                    },
                    onHorizontalDragEnd: (details) async {
                      if (_dragPosition > maxDrag * 0.65 && !_isSubmitting) {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setState(() {
                          _dragPosition = maxDrag;
                          _isSubmitting = true;
                        });

                        final success = await OrderService.markOrderDelivered(order.id);

                        if (mounted) {
                          setState(() {
                            _isCompleted = success;
                            _isSubmitting = false;
                          });

                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text('Order marked as Delivered and moved to Delivered Orders!'),
                                  ],
                                ),
                              ),
                            );

                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (navigator.canPop()) {
                                navigator.popUntil((route) => route.isFirst);
                              }
                            });
                          }
                        }
                      } else {
                        setState(() {
                          _dragPosition = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8E635),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isSubmitting
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1B3E19)),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1B3E19), size: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineRow({
    required String title,
    required String subtitle,
    required String time,
    bool isCompleted = false,
    bool isActive = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (isCompleted)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B3E19),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              )
            else if (isActive)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFBEF264),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF1B3E19)),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B3E19),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
