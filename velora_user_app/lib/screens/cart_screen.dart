import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart' as db_cart;
import 'home_screen.dart' show VeloraColors;
import 'checkout_screen.dart';
import '../services/recommendation_service.dart';
import '../services/user_activity_service.dart';
import '../widgets/recommended_products_section.dart';

// ─── Cart Item UI Model ───────────────────────────────────────────────────────

class CartItem {
  final db_cart.CartItem? source;
  final String name;
  final String description;
  final double unitPrice;
  final String? imagePath;
  final IconData fallbackIcon;
  int quantity;

  CartItem({
    this.source,
    required this.name,
    required this.description,
    required this.unitPrice,
    this.imagePath,
    required this.fallbackIcon,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
}

// ─── Cart Screen ──────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponCtrl = TextEditingController();
  double _discount = 0.0;
  bool _couponApplied = false;
  String _couponMsg = '';

  List<CartItem> _getDisplayItems() {
    final dbItems = CartService.instance.items;
    if (dbItems.isEmpty) return [];

    return dbItems.map((item) {
      return CartItem(
        source: item,
        name: item.title,
        description: item.description.isNotEmpty ? item.description : item.category,
        unitPrice: item.price,
        imagePath: item.imageUrl.isNotEmpty ? item.imageUrl : null,
        fallbackIcon: Icons.shopping_basket_rounded,
        quantity: item.quantity,
      );
    }).toList();
  }

  double get _subtotal => CartService.instance.subtotal;

  double get _total {
    final t = _subtotal - _discount;
    return t > 0 ? t : 0.0;
  }

  int get _totalItems => CartService.instance.totalItemCount;

  void _increment(CartItem item) {
    if (item.source != null) {
      CartService.instance.updateQuantity(item.source!, item.quantity + 1);
    }
  }

  void _decrement(CartItem item) {
    if (item.source != null) {
      CartService.instance.updateQuantity(item.source!, item.quantity - 1);
    }
  }

  void _remove(CartItem item) {
    if (item.source != null) {
      UserActivityService.instance.logRemoveFromCart(
        productId: item.source!.productId,
        productName: item.name,
        categoryName: item.source!.category,
      );
      CartService.instance.removeItem(item.source!);
    }
  }

  void _applyCoupon() {
    final code = _couponCtrl.text.trim().toUpperCase();
    FocusScope.of(context).unfocus();
    if (code == 'VELORA10') {
      setState(() {
        _discount = _subtotal * 0.10;
        _couponApplied = true;
        _couponMsg = '10% off applied!';
      });
    } else if (code == 'SAVE1') {
      setState(() {
        _discount = 1.00;
        _couponApplied = true;
        _couponMsg = 'Rs 1.00 off applied!';
      });
    } else {
      setState(() {
        _discount = 0.0;
        _couponApplied = false;
        _couponMsg = 'Invalid coupon code.';
      });
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }


  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final items = _getDisplayItems();
        return Scaffold(
          backgroundColor: const Color(0xFFF7F4EE),
          body: SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // ── App Bar ──────────────────────────────────────────────
                    _buildAppBar(),

                    // ── Page Title ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: Text(
                          items.isEmpty
                              ? 'My Cart (0 Items)'
                              : 'My Cart ($_totalItems Item${_totalItems == 1 ? '' : 's'})',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),

                    // ── Empty state ──────────────────────────────────────────
                    if (items.isEmpty)
                      SliverFillRemaining(child: _buildEmptyCart()),

                    // ── Cart Items ───────────────────────────────────────────
                    if (items.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _CartItemCard(
                              item: items[i],
                              onIncrement: () => _increment(items[i]),
                              onDecrement: () => _decrement(items[i]),
                              onRemove: () => _remove(items[i]),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      ),

                    // ── Complete Your Order (Recommendations) ─────────
                    if (items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 4),
                          child: RecommendedProductsSection(
                            title: 'Complete Your Order',
                            subtitle: 'Frequently paired with items in your cart',
                            badgeText: 'PAIR WITH',
                            type: RecommendationSectionType.cartCrossSell,
                            fetchProducts: () => RecommendationService.instance.getCartRecommendations(limit: 6),
                          ),
                        ),
                      ),

                    // ── Order Summary ────────────────────────────────────────
                    if (items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: _buildOrderSummary(),
                        ),
                      ),

                    // ── Bottom padding ───────────────────────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: 130)),
                  ],
                ),

                // ── Proceed to Checkout ─────────────────────────────────────
                if (items.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildCheckoutBar(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ─── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF7F4EE),
      elevation: 0,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF3A5A2A),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ─── Order Summary ─────────────────────────────────────────────────────────

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
              Text(
                'Rs ${_subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Coupon code row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0D8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _couponApplied
                          ? const Color(0xFF4A7C20)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _couponCtrl,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Coupon Code',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFFBBA96A),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _applyCoupon,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A5A1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Apply',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Coupon feedback message
          if (_couponMsg.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _couponApplied
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 13,
                  color: _couponApplied
                      ? const Color(0xFF4A7C20)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 5),
                Text(
                  _couponMsg,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _couponApplied
                        ? const Color(0xFF4A7C20)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Discount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
              Text(
                _discount > 0
                    ? '-Rs ${_discount.toStringAsFixed(2)}'
                    : 'Rs 0.00',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _discount > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Divider
          Divider(color: const Color(0xFFE5E7EB), height: 1),

          const SizedBox(height: 14),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Rs ${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFCEE847),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Checkout Bar ──────────────────────────────────────────────────────────

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EE),
        border: Border(
          top: BorderSide(
              color: Colors.black.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (ctx, anim, _) => CheckoutScreen(cartTotal: _total),
              transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );

        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: VeloraColors.lime,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: VeloraColors.lime.withValues(alpha: 0.50),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF1A2D5A), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty Cart ────────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 46, color: Color(0xFF3A5A2A)),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding fresh products!',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: VeloraColors.lime,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: VeloraColors.lime.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Start Shopping',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2D5A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 0.02,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  Widget _buildProductImage(CartItem item) {
    if (item.imagePath == null || item.imagePath!.trim().isEmpty) {
      return _buildFallbackImage(item.fallbackIcon);
    }
    String path = item.imagePath!.trim();
    if (path.startsWith('assets/')) {
      path = path.replaceFirst('assets/', 'assests/');
    }
    final bool isNetwork = path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.contains('cloudinary.com');

    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackImage(item.fallbackIcon),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackImage(item.fallbackIcon),
      );
    }
  }

  Widget _buildFallbackImage(IconData fallbackIcon) {
    return Container(
      color: const Color(0xFFF0F5D8),
      child: Center(
        child: Icon(fallbackIcon, size: 36, color: const Color(0xFF3A5A2A)),
      ),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Image ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _buildProductImage(item),
                ),
              ),

              const SizedBox(width: 14),

              // ── Details ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + delete row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onRemove,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Description
                    Text(
                      item.description,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Price + Quantity stepper
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Rs ${item.total.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF3A5A1E),
                          ),
                        ),
                        const Spacer(),
                        // Quantity stepper
                        _QuantityStepper(
                          quantity: item.quantity,
                          onDecrement: widget.onDecrement,
                          onIncrement: widget.onIncrement,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quantity Stepper ─────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5C8),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: quantity > 1,
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                '$quantity',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2D1A),
                ),
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? const Color(0xFF111827)
              : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
