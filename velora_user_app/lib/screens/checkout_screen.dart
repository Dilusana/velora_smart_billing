import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_success_screen.dart';

// ─── Checkout Screen ──────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final double cartTotal;
  const CheckoutScreen({super.key, this.cartTotal = 23.10});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Form controllers
  final _nameCtrl = TextEditingController(text: 'John Doe');
  final _phoneCtrl = TextEditingController(text: '+1(555)000-0000');

  // State
  bool _isPickup = true;
  int _selectedPayment = 0; // 0=Visa, 1=Apple Pay, 2=G-Pay
  bool _summaryExpanded = true;

  // Demo items
  static const _items = [
    _CheckoutItem(name: 'Organic Strawberries', qty: 1, unitPrice: 4.99,
        imagePath: 'assests/veg_fruits.png', fallbackIcon: Icons.eco_rounded),
    _CheckoutItem(name: 'Pure Green Juice', qty: 2, unitPrice: 6.50,
        imagePath: 'assests/beverages.png', fallbackIcon: Icons.local_drink_rounded),
    _CheckoutItem(name: 'Artisan Sourdough', qty: 1, unitPrice: 5.25,
        imagePath: 'assests/sourdough_product.jpg', fallbackIcon: Icons.breakfast_dining_rounded),
  ];

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _tax => _subtotal * 0.08;
  double get _discount => 2.00;
  double get _total => _subtotal + _tax - _discount;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E8),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFFF5F2E8),
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
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF3A5A2A)),
                          ),
                        ),
                        const Spacer(),
                        Text('Checkout',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                        const Spacer(),
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

                // ── Step Indicator ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: _buildStepIndicator(),
                  ),
                ),

                // ── Customer Information ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _buildSection(
                      icon: Icons.person_rounded,
                      iconBg: const Color(0xFFEEF5C8),
                      iconColor: const Color(0xFF3A5A2A),
                      title: 'Customer Information',
                      child: Column(
                        children: [
                          _FormField(label: 'FULL NAME', controller: _nameCtrl, icon: Icons.person_outline_rounded),
                          const SizedBox(height: 14),
                          _FormField(label: 'PHONE NUMBER', controller: _phoneCtrl, icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Fulfillment Method ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _buildSection(
                      icon: Icons.local_shipping_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Fulfillment Method',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0E8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _ToggleBtn(
                                  label: 'Pickup',
                                  icon: Icons.store_rounded,
                                  isSelected: _isPickup,
                                  onTap: () => setState(() => _isPickup = true),
                                )),
                                Expanded(child: _ToggleBtn(
                                  label: 'Delivery',
                                  icon: Icons.delivery_dining_rounded,
                                  isSelected: !_isPickup,
                                  onTap: () => setState(() => _isPickup = false),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Address info
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isPickup
                                ? _FulfillmentInfo(
                                    key: const ValueKey('pickup'),
                                    icon: Icons.location_on_rounded,
                                    text: 'SmartMarket Downtown: Main Entrance Kiosk. Ready in 15 mins.',
                                  )
                                : _FulfillmentInfo(
                                    key: const ValueKey('delivery'),
                                    icon: Icons.home_rounded,
                                    text: '123 Green Lane, Freshville. Estimated: 35–45 mins.',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Payment Method ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _buildSection(
                      icon: Icons.credit_card_rounded,
                      iconBg: const Color(0xFFFEF9C3),
                      iconColor: const Color(0xFFA16207),
                      title: 'Payment Method',
                      child: Column(
                        children: [
                          // Credit card
                          GestureDetector(
                            onTap: () => setState(() => _selectedPayment = 0),
                            child: _CreditCard(isSelected: _selectedPayment == 0),
                          ),
                          const SizedBox(height: 12),
                          // Apple Pay + G-Pay row
                          Row(
                            children: [
                              Expanded(child: _PaymentOption(
                                label: 'Apple Pay',
                                icon: Icons.apple_rounded,
                                isSelected: _selectedPayment == 1,
                                onTap: () => setState(() => _selectedPayment = 1),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _PaymentOption(
                                label: 'G-Pay',
                                icon: Icons.g_mobiledata_rounded,
                                isSelected: _selectedPayment == 2,
                                onTap: () => setState(() => _selectedPayment = 2),
                              )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Add new
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5, style: BorderStyle.solid),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6B7280), size: 18),
                                  const SizedBox(width: 8),
                                  Text('Add New Payment Method',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Order Summary ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _buildSection(
                      icon: Icons.receipt_rounded,
                      iconBg: const Color(0xFFEEF5C8),
                      iconColor: const Color(0xFF3A5A2A),
                      title: 'Order Summary',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5C8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${_items.length} Items',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3A5A2A))),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: _summaryExpanded ? 0 : 0.5,
                              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF3A5A2A), size: 22),
                            ),
                          ),
                        ],
                      ),
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _summaryExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        firstChild: Column(
                          children: [
                            ..._items.map((item) => _OrderSummaryRow(item: item)),
                            const SizedBox(height: 10),
                            Divider(color: const Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 10),
                            _SummaryLine(label: 'Subtotal', value: 'Rs ${_subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 5),
                            _SummaryLine(label: 'Tax (8%)', value: 'Rs ${_tax.toStringAsFixed(2)}'),
                            const SizedBox(height: 5),
                            _SummaryLine(label: 'Promo Discount', value: '-\$${_discount.toStringAsFixed(2)}',
                              valueColor: const Color(0xFF3A5A2A), labelColor: const Color(0xFF3A5A2A)),
                            const SizedBox(height: 12),
                            Divider(color: const Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Amount',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                                Text('Rs ${_total.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                              ],
                            ),
                          ],
                        ),
                        secondChild: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount',
                              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280))),
                            Text('Rs ${_total.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 130)),
              ],
            ),

            // ── Confirm Payment ──────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildConfirmBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const steps = ['INFO', 'SUMMARY', 'PAYMENT'];
    const activeSteps = [true, true, false];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final leftDone = activeSteps[i ~/ 2];
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: leftDone ? const Color(0xFFCEE847) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final idx = i ~/ 2;
        final isActive = activeSteps[idx];
        return Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFFCEE847) : const Color(0xFFF3F4F6),
                border: isActive ? null : Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFFCEE847).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Center(
                child: Text('${idx + 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w900,
                    color: isActive ? const Color(0xFF1A2D5A) : const Color(0xFF9CA3AF),
                  )),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[idx],
              style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                color: isActive ? const Color(0xFF3A5A2A) : const Color(0xFF9CA3AF),
              )),
          ],
        );
      }),
    );
  }

  // ─── Card Section wrapper ─────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
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
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── Bottom Confirm Bar ────────────────────────────────────────────────────────

  Widget _buildConfirmBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2E8),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (ctx, anim, _) => PaymentSuccessScreen(
                    orderId: 'SM-8829',
                    totalPaid: _total,
                  ),
                  transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
                    opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFCEE847),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFFCEE847).withValues(alpha: 0.50), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Confirm Payment',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A2D5A)),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A2D5A), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('Secure 256-bit SSL encrypted payment',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Checkout Item Model ──────────────────────────────────────────────────────

class _CheckoutItem {
  final String name;
  final int qty;
  final double unitPrice;
  final String? imagePath;
  final IconData fallbackIcon;

  const _CheckoutItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.imagePath,
    required this.fallbackIcon,
  });

  double get total => qty * unitPrice;
}

// ─── Form Field ───────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
            color: const Color(0xFF9CA3AF), letterSpacing: 0.7)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 17, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151)),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Toggle Button ────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleBtn({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCEE847) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFCEE847).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF1A2D5A) : const Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF1A2D5A) : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

// ─── Fulfillment Info ─────────────────────────────────────────────────────────

class _FulfillmentInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FulfillmentInfo({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3A5A2A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF374151), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Credit Card ──────────────────────────────────────────────────────────────

class _CreditCard extends StatelessWidget {
  final bool isSelected;
  const _CreditCard({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2340), Color(0xFF2D3E6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected ? const Color(0xFFCEE847) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF1A2340).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          // Background circle decorations
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 20, bottom: -30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: chip + VISA
                Row(
                  children: [
                    Container(
                      width: 28, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Visa badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('VISA', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 1.5)),
                          const SizedBox(width: 4),
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFCEE847),
                            ),
                            child: const Icon(Icons.check_rounded, size: 9, color: Color(0xFF1A2D5A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Card number
                Text('•••• •••• •••• 4242',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.90), letterSpacing: 2)),
                const Spacer(),
                // Cardholder + expiry
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARDHOLDER', style: GoogleFonts.outfit(fontSize: 8, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                        Text('JOHN DOE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EXPIRY', style: GoogleFonts.outfit(fontSize: 8, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                        Text('12/26', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
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
}

// ─── Payment Option (Apple Pay / G-Pay) ──────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF5C8) : const Color(0xFFF9F9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3A5A2A) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isSelected ? const Color(0xFF3A5A2A) : const Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF3A5A2A) : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

// ─── Order Summary Item Row ───────────────────────────────────────────────────

class _OrderSummaryRow extends StatelessWidget {
  final _CheckoutItem item;
  const _OrderSummaryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44, height: 44,
              child: item.imagePath != null
                  ? Image.asset(item.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF0F5D8),
                        child: Icon(item.fallbackIcon, size: 22, color: const Color(0xFF3A5A2A))))
                  : Container(color: const Color(0xFFF0F5D8),
                      child: Icon(item.fallbackIcon, size: 22, color: const Color(0xFF3A5A2A))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item.qty}x \$${item.unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Text('Rs ${item.total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
        ],
      ),
    );
  }
}

// ─── Summary Line ─────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;

  const _SummaryLine({required this.label, required this.value, this.labelColor, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: labelColor ?? const Color(0xFF6B7280))),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF374151))),
      ],
    );
  }
}
