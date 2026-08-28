import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import '../services/firebase_auth_service.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import 'payment_success_screen.dart';

// ─── Credit Card Model ────────────────────────────────────────────────────────

class CreditCardModel {
  final String id;
  final String cardholderName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String cardType;

  const CreditCardModel({
    required this.id,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.cardType,
  });

  String get last4 {
    final clean = cardNumber.replaceAll(' ', '').replaceAll('-', '');
    return clean.length >= 4 ? clean.substring(clean.length - 4) : '4242';
  }

  String get maskedNumber => '•••• •••• •••• $last4';
}

// ─── Checkout Screen ──────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final double cartTotal;
  const CheckoutScreen({super.key, this.cartTotal = 23.10});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Form controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  StreamSubscription<UserProfile>? _userSub;
  String _customerAddress = '742 Evergreen Terrace, Springfield';

  // State
  bool _isPickup = true;
  int _selectedPayment = 0; // 0=Card, 1=Cash, 2=G-Pay
  bool _summaryExpanded = true;
  bool _isSubmitting = false;

  final List<CreditCardModel> _savedCards = [
    const CreditCardModel(
      id: 'card_1',
      cardholderName: 'Alex Johnson',
      cardNumber: '4532 7512 8901 4242',
      expiryDate: '12/26',
      cvv: '123',
      cardType: 'VISA',
    ),
  ];
  int _selectedCardIndex = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuthService.instance.currentUser?.uid ?? UserRepository.defaultUserId;
    _userSub = UserRepository.instance.getUserProfileStream(userId: uid).listen((profile) {
      if (mounted) {
        setState(() {
          _nameCtrl.text = profile.name;
          _phoneCtrl.text = profile.phone;
          if (profile.address.isNotEmpty) {
            _customerAddress = profile.address;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  List<_CheckoutItem> get _checkoutItems {
    final cartItems = CartService.instance.items;
    if (cartItems.isEmpty) {
      return [
        _CheckoutItem(
          name: 'Fresh Items',
          qty: 1,
          unitPrice: widget.cartTotal > 0 ? widget.cartTotal : 23.10,
          fallbackIcon: Icons.shopping_basket_rounded,
        ),
      ];
    }
    return cartItems.map((i) => _CheckoutItem(
      name: i.title,
      qty: i.quantity,
      unitPrice: i.price,
      imagePath: i.imageUrl.isNotEmpty ? i.imageUrl : null,
      fallbackIcon: Icons.shopping_basket_rounded,
    )).toList();
  }

  double get _subtotal {
    final s = CartService.instance.subtotal;
    return s > 0 ? s : widget.cartTotal;
  }

  double get _deliveryFee => _isPickup ? 0.0 : 300.0;
  double get _discount => 0.0;
  double get _total => _subtotal + _deliveryFee - _discount;

  Future<void> _processCheckout() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    HapticFeedback.mediumImpact();

    final paymentMethods = ['Card', 'Cash', 'Google Pay'];
    final pMethod = paymentMethods[_selectedPayment % paymentMethods.length];

    final cartItems = CartService.instance.items;

    String orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      if (cartItems.isNotEmpty) {
        orderId = await OrderRepository.instance.submitOrder(
          items: cartItems,
          subtotal: _subtotal,
          discount: _discount,
          deliveryFee: _deliveryFee,
          total: _total,
          paymentMethod: pMethod,
          customerId: UserRepository.defaultUserId,
          customerName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Alex Johnson',
          deliveryAddress: _isPickup ? 'Store Pickup (Main Branch)' : _customerAddress,
          deliveryType: _isPickup ? 'pickup' : 'delivery',
          phone: _phoneCtrl.text,
        );
      }
    } catch (e) {
      debugPrint('Order submit error: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => PaymentSuccessScreen(
          orderId: orderId,
          totalPaid: _total,
        ),
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showAddCardDialog() {
    final nameCtrl = TextEditingController(text: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Alex Johnson');
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    String cardType = 'VISA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: Color(0xFF1A2D5A), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Add Debit / Credit Card',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'CARD TYPE',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.7),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['VISA', 'MASTERCARD', 'AMEX'].map((type) {
                        final isSel = cardType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSel,
                            selectedColor: const Color(0xFF1A2D5A),
                            backgroundColor: const Color(0xFFF3F4F6),
                            labelStyle: GoogleFonts.outfit(
                              color: isSel ? Colors.white : const Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (sel) {
                              if (sel) {
                                setModalState(() => cardType = type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    _FormField(label: 'CARDHOLDER NAME', controller: nameCtrl, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),

                    _FormField(
                      label: 'CARD NUMBER',
                      controller: numberCtrl,
                      icon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: 'EXPIRY DATE (MM/YY)',
                            controller: expiryCtrl,
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: 'CVV',
                            controller: cvvCtrl,
                            icon: Icons.lock_outline_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (numberCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter cardholder name and card number.', style: GoogleFonts.outfit(color: Colors.white)),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          final newCard = CreditCardModel(
                            id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                            cardholderName: nameCtrl.text.trim(),
                            cardNumber: numberCtrl.text.trim(),
                            expiryDate: expiryCtrl.text.trim().isNotEmpty ? expiryCtrl.text.trim() : '12/28',
                            cvv: cvvCtrl.text.trim().isNotEmpty ? cvvCtrl.text.trim() : '123',
                            cardType: cardType,
                          );

                          setState(() {
                            _savedCards.add(newCard);
                            _selectedCardIndex = _savedCards.length - 1;
                            _selectedPayment = 0;
                          });

                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Card added successfully!', style: GoogleFonts.outfit(color: Colors.white)),
                              backgroundColor: const Color(0xFF3A5A2A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2D5A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Save & Select Card',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFEEF5C8), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF3A5A2A)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: _CheckoutStepper(currentStep: 2)),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // ── Customer Information ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _buildSection(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFEEF5C8),
                      iconColor: const Color(0xFF3A5A2A),
                      title: 'Customer Information',
                      child: Column(
                        children: [
                          _FormField(label: 'FULL NAME', controller: _nameCtrl, icon: Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _FormField(label: 'PHONE NUMBER', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
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
                      icon: Icons.local_shipping_outlined,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0369A1),
                      title: 'Fulfillment Method',
                      child: Column(
                        children: [
                          _FulfillmentToggle(
                            isPickup: _isPickup,
                            onChanged: (val) => setState(() => _isPickup = val),
                          ),
                          const SizedBox(height: 12),
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
                                    text: '$_customerAddress. Estimated: 35–45 mins. (Delivery Fee: Rs 300.00)',
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
                            child: _CreditCard(
                              isSelected: _selectedPayment == 0,
                              card: _savedCards[_selectedCardIndex],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cash + G-Pay row
                          Row(
                            children: [
                              Expanded(child: _PaymentOption(
                                label: 'Cash',
                                icon: Icons.local_atm_rounded,
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
                            onTap: _showAddCardDialog,
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
                            child: Text('${_checkoutItems.length} Items',
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
                            ..._checkoutItems.map((item) => _OrderSummaryRow(item: item)),

                            const SizedBox(height: 10),
                            Divider(color: const Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 10),
                            _SummaryLine(label: 'Subtotal', value: 'Rs ${_subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 5),
                            _SummaryLine(
                              label: 'Delivery Fee',
                              value: _isPickup ? 'Free (Pickup)' : 'Rs ${_deliveryFee.toStringAsFixed(2)}',
                              valueColor: _isPickup ? const Color(0xFF3A5A2A) : const Color(0xFF111827),
                            ),
                            if (_discount > 0) ...[
                              const SizedBox(height: 5),
                              _SummaryLine(
                                label: 'Promo Discount',
                                value: '-Rs ${_discount.toStringAsFixed(2)}',
                                valueColor: const Color(0xFF3A5A2A),
                                labelColor: const Color(0xFF3A5A2A),
                              ),
                            ],
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

  Widget _buildSection({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildConfirmBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCEE847),
                  foregroundColor: const Color(0xFF1A2D5A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A2D5A)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Confirm Payment',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2D5A))),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF1A2D5A)),
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

// ─── Checkout Item Model ──────────────────────────────────────────────────────

class _CheckoutItem {
  final String name;
  final int qty;
  final double unitPrice;
  final String? imagePath;
  final IconData fallbackIcon;

  _CheckoutItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.imagePath,
    required this.fallbackIcon,
  });

  double get total => qty * unitPrice;
}

// ─── Stepper Widget ───────────────────────────────────────────────────────────

class _CheckoutStepper extends StatelessWidget {
  final int currentStep;
  const _CheckoutStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Cart', 'Summary', 'Payment'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final isDone = stepIdx < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? const Color(0xFFCEE847) : const Color(0xFFE5E7EB),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isCurrent = stepIdx == currentStep;
          final isDone = stepIdx < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent ? const Color(0xFFCEE847) : const Color(0xFFF3F4F6),
                  border: Border.all(
                    color: isCurrent ? const Color(0xFF3A5A2A) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF3A5A2A))
                      : Text(
                          '${stepIdx + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isCurrent ? const Color(0xFF3A5A2A) : const Color(0xFF9CA3AF),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIdx].toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: isCurrent ? const Color(0xFF3A5A2A) : const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Form Field Helper ────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.7),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9F9F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A5A2A), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─── Fulfillment Toggle ───────────────────────────────────────────────────────

class _FulfillmentToggle extends StatelessWidget {
  final bool isPickup;
  final ValueChanged<bool> onChanged;

  const _FulfillmentToggle({required this.isPickup, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleBtn(
              label: 'Pickup',
              icon: Icons.storefront_rounded,
              isSelected: isPickup,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: 'Delivery',
              icon: Icons.delivery_dining_rounded,
              isSelected: !isPickup,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

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
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCEE847) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF3A5A2A) : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF3A5A2A) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FulfillmentInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FulfillmentInfo({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3A5A2A)),
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

// ─── Credit Card Widget ───────────────────────────────────────────────────────

class _CreditCard extends StatelessWidget {
  final bool isSelected;
  final CreditCardModel card;
  const _CreditCard({required this.isSelected, required this.card});

  @override
  Widget build(BuildContext context) {
    final displayName = card.cardholderName.trim().isNotEmpty
        ? card.cardholderName.trim().toUpperCase()
        : 'ALEX JOHNSON';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 150,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(card.cardType.toUpperCase(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 1.5)),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFCEE847),
                              ),
                              child: const Icon(Icons.check_rounded, size: 9, color: Color(0xFF1A2D5A)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(card.maskedNumber,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.90), letterSpacing: 2)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARDHOLDER', style: GoogleFonts.outfit(fontSize: 8, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                          Text(displayName, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EXPIRY', style: GoogleFonts.outfit(fontSize: 8, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                        Text(card.expiryDate, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
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

// ─── Payment Option (Cash / G-Pay) ──────────────────────────────────────────

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

  Widget _buildImage(String? path, IconData fallbackIcon) {
    if (path == null || path.trim().isEmpty) {
      return _buildFallback(fallbackIcon);
    }
    String formatted = path.trim();
    if (formatted.startsWith('assets/')) {
      formatted = formatted.replaceFirst('assets/', 'assests/');
    }
    final bool isNetwork = formatted.startsWith('http://') ||
        formatted.startsWith('https://') ||
        formatted.contains('cloudinary.com') ||
        formatted.contains('firebasestorage.googleapis.com');

    if (isNetwork) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallback(fallbackIcon),
      );
    } else {
      return Image.asset(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallback(fallbackIcon),
      );
    }
  }

  Widget _buildFallback(IconData fallbackIcon) {
    return Container(
      color: const Color(0xFFF0F5D8),
      child: Center(
        child: Icon(fallbackIcon, size: 22, color: const Color(0xFF3A5A2A)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _buildImage(item.imagePath, item.fallbackIcon),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.qty}x Rs ${item.unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Text(
            'Rs ${item.total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
          ),
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
