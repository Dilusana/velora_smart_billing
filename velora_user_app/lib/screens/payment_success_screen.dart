import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_tracker_screen.dart';
import 'orders_screen.dart';

// ─── Payment Success Screen ───────────────────────────────────────────────────

class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  final double totalPaid;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalPaid,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _stickersCtrl;
  late AnimationController _cardCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _stickersAnim;
  late Animation<double> _cardAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _stickersCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _stickersAnim = CurvedAnimation(parent: _stickersCtrl, curve: Curves.easeOutBack);
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic);

    // Chain animations
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _stickersCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _stickersCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  // Estimated delivery time (now + 45 min)
  String get _estimatedDelivery {
    final now = DateTime.now();
    final delivery = now.add(const Duration(minutes: 45));
    final hour = delivery.hour % 12 == 0 ? 12 : delivery.hour % 12;
    final min = delivery.minute.toString().padLeft(2, '0');
    final period = delivery.hour < 12 ? 'AM' : 'PM';
    return 'Today, $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // ── App Bar ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_rounded, color: Color(0xFF3A5A2A), size: 20),
                        ),
                        const Spacer(),
                        Text('Fresh & Green',
                          style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: const Color(0xFF3A5A2A), letterSpacing: 0.3,
                          )),
                        const Spacer(),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF3A5A2A), size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Animated Success Circle ────────────────────────────
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Floating sticker — top right (party popper)
                        Positioned(
                          top: 10, right: 60,
                          child: ScaleTransition(
                            scale: _stickersAnim,
                            child: Transform.rotate(
                              angle: 0.3,
                              child: Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF9C3),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: const Center(
                                  child: Text('🎉', style: TextStyle(fontSize: 26)),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Floating sticker — left (basket)
                        Positioned(
                          bottom: 30, left: 50,
                          child: ScaleTransition(
                            scale: _stickersAnim,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F5D8),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: const Center(
                                  child: Icon(Icons.shopping_basket_rounded, color: Color(0xFF3A5A2A), size: 24),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Outer glow ring
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 160, height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFCEE847).withValues(alpha: 0.25),
                            ),
                          ),
                        ),

                        // Middle lime ring
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 130, height: 130,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCEE847),
                            ),
                          ),
                        ),

                        // Inner dark olive circle with checkmark
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 100, height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3A5A2A),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── "Order Placed!" ────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text('Order Placed!',
                          style: GoogleFonts.outfit(
                            fontSize: 36, fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2D1A), height: 1.1,
                          )),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Your order has been successfully placed. We\'ll notify you when it\'s out for delivery.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14, color: const Color(0xFF4B5563),
                              fontWeight: FontWeight.w400, height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Transaction Summary Card ───────────────────────────
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(_cardAnim),
                    child: FadeTransition(
                      opacity: _cardAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 20, offset: const Offset(0, 6),
                            )],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                                child: Row(
                                  children: [
                                    Text('TRANSACTION SUMMARY',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11, fontWeight: FontWeight.w700,
                                        color: const Color(0xFF9CA3AF), letterSpacing: 0.7,
                                      )),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCEE847),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('VERIFIED',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10, fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1A2D5A), letterSpacing: 0.5,
                                        )),
                                    ),
                                  ],
                                ),
                              ),

                              // Divider strip
                              Container(height: 1, color: const Color(0xFFF3F4F6)),

                              // Order ID + Total Paid grid
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F2E0),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Order ID',
                                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF))),
                                            const SizedBox(height: 4),
                                            Text('#${widget.orderId}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 16, fontWeight: FontWeight.w900,
                                                color: const Color(0xFF1A2D1A),
                                              )),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F2E0),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Total Paid',
                                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF))),
                                            const SizedBox(height: 4),
                                            Text('Rs ${widget.totalPaid.toStringAsFixed(2)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 16, fontWeight: FontWeight.w900,
                                                color: const Color(0xFF3A5A2A),
                                              )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Estimated Delivery
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F2E0),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38, height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                                        ),
                                        child: const Icon(Icons.access_time_rounded, color: Color(0xFF3A5A2A), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Estimated Delivery',
                                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF))),
                                          const SizedBox(height: 2),
                                          Text(_estimatedDelivery,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15, fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1A2D1A),
                                            )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Track Order Button ─────────────────────────────────
                  FadeTransition(
                    opacity: _cardAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (ctx, anim, _) => OrderTrackerScreen(
                                  order: demoOrders[1], // Processing order
                                ),
                                transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                  child: child,
                                ),
                                transitionDuration: const Duration(milliseconds: 350),
                              ),
                            ),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A5A2A),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFF3A5A2A).withValues(alpha: 0.35),
                                  blurRadius: 14, offset: const Offset(0, 6),
                                )],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, color: Color(0xFFCEE847), size: 22),
                                  const SizedBox(width: 10),
                                  Text('Track Order',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                                    )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to Home
                          GestureDetector(
                            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF3A5A2A)),
                                const SizedBox(width: 6),
                                Text('Back to Home',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3A5A2A),
                                  )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Nav ─────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_outlined, label: 'Home', isActive: false,
                      onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                    _NavItem(icon: Icons.grid_view_outlined, label: 'Categories', isActive: false, onTap: () {}),
                    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', isActive: true, onTap: () {}),
                    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Cart', isActive: false, onTap: () {}),
                    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', isActive: false, onTap: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 56 : 44,
            height: isActive ? 44 : 44,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3A5A2A) : Colors.transparent,
              borderRadius: BorderRadius.circular(isActive ? 14 : 0),
            ),
            child: Center(
              child: Icon(icon,
                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                size: 22),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.outfit(
              fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? const Color(0xFF3A5A2A) : const Color(0xFF9CA3AF),
            )),
        ],
      ),
    );
  }
}
