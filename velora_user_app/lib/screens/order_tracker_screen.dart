import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_screen.dart';

// ─── Order Tracker Screen ─────────────────────────────────────────────────────

class OrderTrackerScreen extends StatefulWidget {
  final Order order;
  const OrderTrackerScreen({super.key, required this.order});

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  // For ORD-3012 (processing) → Out for Delivery step is active
  static const _steps = [
    _DeliveryStep(
      label: 'Order Placed',
      sublabel: 'Your order was received',
      icon: Icons.shopping_bag_rounded,
      isDone: true,
    ),
    _DeliveryStep(
      label: 'Order Prepared',
      sublabel: 'Items are packed & ready',
      icon: Icons.inventory_2_rounded,
      isDone: true,
    ),
    _DeliveryStep(
      label: 'Out for Delivery',
      sublabel: 'Rider is on the way',
      icon: Icons.delivery_dining_rounded,
      isDone: false,
      isActive: true,
    ),
    _DeliveryStep(
      label: 'Delivered',
      sublabel: 'Estimated: ~30 min',
      icon: Icons.home_rounded,
      isDone: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 58,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF3A5A2A)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Track Order',
                            style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                        ),
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFFCEE847), Color(0xFF8DC63F)]),
                          ),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF1A2D5A), size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Map View ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 210,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Stack(
                      children: [
                        // Simulated map background
                        CustomPaint(
                          size: const Size(double.infinity, 210),
                          painter: _MapPainter(),
                        ),

                        // Pulsing delivery location pin
                        Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (ctx, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse
                                  Transform.scale(
                                    scale: 1.0 + _pulseCtrl.value * 0.6,
                                    child: Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCEE847).withValues(alpha: 0.25 - _pulseCtrl.value * 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Inner dot
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3A5A2A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: const Color(0xFF3A5A2A).withValues(alpha: 0.4), blurRadius: 10)],
                                    ),
                                    child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFFCEE847), size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Status pill at top
                        Positioned(
                          top: 12, left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A5A2A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.delivery_dining_rounded, color: Color(0xFFCEE847), size: 14),
                                const SizedBox(width: 6),
                                Text('On the way', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),

                        // Edit map button
                        Positioned(
                          top: 12, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_location_alt_rounded, size: 13, color: Color(0xFF3A5A2A)),
                                const SizedBox(width: 4),
                                Text('Edit map', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3A5A2A))),
                              ],
                            ),
                          ),
                        ),

                        // Delivery time badge at bottom
                        Positioned(
                          bottom: 12, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF3A5A2A)),
                                  const SizedBox(width: 6),
                                  Text('Arriving in ~28 min', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Courier Card ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_slideAnim),
                      child: FadeTransition(
                        opacity: _slideAnim,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFCEE847), Color(0xFF8DC63F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: const Color(0xFF3A5A2A), width: 2),
                                ),
                                child: const Icon(Icons.person_rounded, color: Color(0xFF1A2D5A), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Alan R.',
                                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                                    Text('Professional Courier',
                                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (i) =>
                                        Icon(i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                                          size: 13, color: const Color(0xFFFBBF24))),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              Row(
                                children: [
                                  _RoundIconBtn(icon: Icons.call_rounded, color: const Color(0xFFDCFCE7), iconColor: const Color(0xFF16A34A)),
                                  const SizedBox(width: 8),
                                  _RoundIconBtn(icon: Icons.chat_bubble_rounded, color: const Color(0xFFEEF5C8), iconColor: const Color(0xFF3A5A2A)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Delivery Progress ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery Progress',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                          const SizedBox(height: 16),
                          ..._steps.asMap().entries.map((e) =>
                            _StepRow(step: e.value, isLast: e.key == _steps.length - 1, pulseCtrl: _pulseCtrl)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Order Items Summary ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Order #${widget.order.id}',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFEEF5C8), borderRadius: BorderRadius.circular(10)),
                                child: Text('${widget.order.itemCount} Items',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF3A5A2A))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...widget.order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40, height: 40,
                                    child: item.imagePath != null
                                        ? Image.asset(item.imagePath!, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: const Color(0xFFF0F5D8),
                                              child: Icon(item.fallbackIcon, size: 20, color: const Color(0xFF3A5A2A))))
                                        : Container(color: const Color(0xFFF0F5D8), child: Icon(item.fallbackIcon, size: 20, color: const Color(0xFF3A5A2A))),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                                      Text(item.unit,
                                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
                                    ],
                                  ),
                                ),
                                Text('Rs ${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A1E))),
                              ],
                            ),
                          )),
                          Divider(color: const Color(0xFFE5E7EB)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
                              Text('Rs ${widget.order.total.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // ── Bottom Nav ─────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2D5A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A2D5A).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_rounded, label: 'Home', isActive: false, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                    _NavItem(icon: Icons.grid_view_rounded, label: 'Categories', isActive: false, onTap: () {}),
                    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Cart', isActive: false, onTap: () {}),
                    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', isActive: true, onTap: () => Navigator.of(context).pop()),
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

// ─── Map Painter ──────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE8F0D8));

    final roadPaint = Paint()..color = Colors.white..strokeWidth = 18..strokeCap = StrokeCap.round;
    final roadOutline = Paint()..color = const Color(0xFFD0D8C0)..strokeWidth = 20..strokeCap = StrokeCap.round;
    final blockPaint = Paint()..color = const Color(0xFFD0DCC0);
    final blockPaint2 = Paint()..color = const Color(0xFFC8D4B8);

    // Building blocks
    final blocks = [
      Rect.fromLTWH(10, 10, 70, 50),
      Rect.fromLTWH(100, 10, 80, 40),
      Rect.fromLTWH(200, 10, 60, 55),
      Rect.fromLTWH(10, 80, 55, 40),
      Rect.fromLTWH(160, 80, 75, 35),
      Rect.fromLTWH(10, 145, 80, 50),
      Rect.fromLTWH(200, 140, 65, 60),
      Rect.fromLTWH(280, 30, 60, 40),
      Rect.fromLTWH(280, 140, 55, 60),
      Rect.fromLTWH(108, 140, 70, 60),
    ];
    for (var i = 0; i < blocks.length; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(blocks[i], const Radius.circular(6)),
          i.isEven ? blockPaint : blockPaint2);
    }

    // Horizontal roads
    for (final y in [70.0, 130.0]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadOutline);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Vertical roads
    for (final x in [90.0, 190.0, 275.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadOutline);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Route line
    final routePaint = Paint()
      ..color = const Color(0xFF3A5A2A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, 130)
      ..lineTo(90, 130)
      ..lineTo(90, 70)
      ..lineTo(190, 70)
      ..lineTo(190, 100)
      ..lineTo(size.width / 2, size.height / 2);
    canvas.drawPath(path, routePaint..color = const Color(0xFFCEE847)..strokeWidth = 5);

    // Random accent dots (parks)
    final parkPaint = Paint()..color = const Color(0xFFA8C890);
    for (final spot in [(45.0, 160.0), (230.0, 155.0), (300.0, 80.0)]) {
      canvas.drawCircle(Offset(spot.$1, spot.$2), 10, parkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Delivery Step Model ──────────────────────────────────────────────────────

class _DeliveryStep {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  const _DeliveryStep({
    required this.label,
    required this.sublabel,
    required this.icon,
    this.isDone = false,
    this.isActive = false,
  });
}

// ─── Step Row ─────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final _DeliveryStep step;
  final bool isLast;
  final AnimationController pulseCtrl;

  const _StepRow({required this.step, required this.isLast, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + line
        Column(
          children: [
            // Circle
            step.isActive
                ? AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (ctx, _) => Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(const Color(0xFF3A5A2A), const Color(0xFF5A8A3A), pulseCtrl.value),
                        boxShadow: [BoxShadow(color: const Color(0xFF3A5A2A).withValues(alpha: 0.3 + pulseCtrl.value * 0.2), blurRadius: 10 + pulseCtrl.value * 5)],
                      ),
                      child: Icon(step.icon, color: const Color(0xFFCEE847), size: 20),
                    ),
                  )
                : Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isDone ? const Color(0xFF3A5A2A) : const Color(0xFFF3F4F6),
                      border: step.isDone ? null : Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                    ),
                    child: step.isDone
                        ? const Icon(Icons.check_rounded, color: Color(0xFFCEE847), size: 20)
                        : Icon(step.icon, color: const Color(0xFFD1D5DB), size: 18),
                  ),

            // Vertical connector
            if (!isLast)
              Container(
                width: 2, height: 32,
                decoration: BoxDecoration(
                  color: step.isDone ? const Color(0xFF3A5A2A) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),

        const SizedBox(width: 14),

        // Text
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: step.isDone || step.isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                )),
              Text(step.sublabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: step.isDone || step.isActive ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                )),
              if (!isLast) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Round Icon Button ────────────────────────────────────────────────────────

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  const _RoundIconBtn({required this.icon, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFCEE847) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              color: isActive ? const Color(0xFF1A2D5A) : Colors.white.withValues(alpha: 0.55),
              size: 22),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
            ],
          ],
        ),
      ),
    );
  }
}
