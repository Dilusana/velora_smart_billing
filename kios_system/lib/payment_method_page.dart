import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'cart_item.dart';
import 'order_repository.dart';

enum PaymentMethod { creditDebitCard, qrPayment, cash, digitalWallet }

class PaymentMethodPage extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final int itemCount;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? userName;

  const PaymentMethodPage({
    super.key,
    this.items = const [],
    this.subtotal = 22.73,
    this.discount = 2.00,
    this.tax = 1.82,
    this.itemCount = 12,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.userName,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage>
    with SingleTickerProviderStateMixin {
  PaymentMethod _selectedMethod = PaymentMethod.creditDebitCard;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _grandTotal => (widget.subtotal - widget.discount + widget.tax).clamp(0.0, double.infinity);

  String _fmt(double v) => 'Rs.${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left: Payment Methods ──────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Methods',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildMethodCard(
                                    method: PaymentMethod.creditDebitCard,
                                    icon: Icons.credit_card_rounded,
                                    label: 'Credit/Debit Card',
                                    subtitle: 'Visa, Mastercard, AMEX',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMethodCard(
                                    method: PaymentMethod.qrPayment,
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: 'QR Payment',
                                    subtitle: 'Scan with phone',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildMethodCard(
                                    method: PaymentMethod.cash,
                                    icon: Icons.payments_outlined,
                                    label: 'Cash',
                                    subtitle: 'Insert bills or coins',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMethodCard(
                                    method: PaymentMethod.digitalWallet,
                                    icon: Icons.account_balance_rounded,
                                    label: 'Digital Wallet',
                                    subtitle: 'Apple Pay, Google Pay',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // ── Right: Payment Summary ─────────────────────────────
                    SizedBox(
                      width: 230,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPaymentSummaryCard(),
                          const SizedBox(height: 14),
                          _buildNeedAssistance(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildPayNowButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primaryText,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KIOSK READY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required PaymentMethod method,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    return Material(
      color: isSelected ? AppColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: isSelected ? 8 : 0,
      shadowColor: AppColors.brand.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.brand : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppColors.brand,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 18),
          _summaryRow('Subtotal', _fmt(widget.subtotal)),
          const SizedBox(height: 10),
          _summaryRow(
            'Discount',
            '-${_fmt(widget.discount)}',
            valueColor: AppColors.accent,
            labelColor: AppColors.accent,
          ),
          const SizedBox(height: 10),
          _summaryRow('Tax', _fmt(widget.tax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F5)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                _fmt(_grandTotal),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECKOUT STATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.monitor_rounded,
                        size: 15, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'POS-402 • Lane 04',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
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

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    Color? labelColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor ?? Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildNeedAssistance() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calling for assistance…')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Need Assistance?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayNowButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handlePayNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 6,
            shadowColor: AppColors.brand.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pay Now',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePayNow() {
    final methodName = switch (_selectedMethod) {
      PaymentMethod.creditDebitCard => 'Credit/Debit Card',
      PaymentMethod.qrPayment => 'QR Payment',
      PaymentMethod.cash => 'Cash',
      PaymentMethod.digitalWallet => 'Digital Wallet',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentProcessingDialog(
        items: widget.items,
        subtotal: widget.subtotal,
        discount: widget.discount,
        total: _grandTotal,
        method: methodName,
        formattedTotal: _fmt(_grandTotal),
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        userName: widget.userName,
      ),
    );
  }
}

class _PaymentProcessingDialog extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String method;
  final String formattedTotal;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? userName;

  const _PaymentProcessingDialog({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.method,
    required this.formattedTotal,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.userName,
  });

  @override
  State<_PaymentProcessingDialog> createState() =>
      _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<_PaymentProcessingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  bool _isProcessing = true;
  bool _isSuccess = false;
  String _errorMessage = '';
  String _orderDocId = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _processCheckout();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    try {
      final docId = await KioskOrderRepository.instance.submitOrder(
        items: widget.items,
        subtotal: widget.subtotal,
        discount: widget.discount,
        total: widget.total,
        paymentMethod: widget.method,
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        userName: widget.userName,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _orderDocId = docId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isProcessing) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync_rounded,
                      color: AppColors.accent, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Processing Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.method} • ${widget.formattedTotal}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Syncing order & stock to Firestore...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ] else if (_isSuccess) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.brand, size: 54),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Order Completed!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brand),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: $_orderDocId',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.method} • ${widget.formattedTotal}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_rounded, color: AppColors.brand, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Synced to Admin Dashboard',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sms_outlined, color: AppColors.brand, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Confirmation SMS pending / sent',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back to Welcome Screen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ] else ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Checkout Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.error),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
