import 'package:flutter/material.dart';

import 'all_deals_page.dart';
import 'cart_database.dart';
import 'cart_item.dart';
import 'my_cart_page.dart';

/// Full-screen product detail page reached by tapping a deal card.
class DealProductDetailPage extends StatefulWidget {
  final DealProduct product;

  const DealProductDetailPage({super.key, required this.product});

  @override
  State<DealProductDetailPage> createState() => _DealProductDetailPageState();
}

class _DealProductDetailPageState extends State<DealProductDetailPage> {
  int _quantity = 1;
  int _cartCount = 0;
  bool _adding = false;

  static const Color _green = Color(0xFF1B8A3D);
  static const Color _orange = Color(0xFFEF6C00);
  static const Color _bg = Color(0xFFF5F6F8);

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  Future<void> _refreshCart() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final item = CartItem(
      category: 'Deals',
      title: widget.product.title,
      description: widget.product.description,
      quantity: _quantity,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    await _refreshCart();
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} × $_quantity added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final subtotal = p.price * _quantity;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageHero(p),
                  _buildBody(p, subtotal),
                ],
              ),
            ),
          ),
          _buildBottomBar(subtotal),
        ],
      ),
    );
  }

  // ── Top green header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Product Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          // Cart icon
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyCartPage()))
                .then((_) => _refreshCart()),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 24),
                  ),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9A825),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green, width: 1.5),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image section ────────────────────────────────────────────────────
  Widget _buildImageHero(DealProduct p) {
    return Container(
      width: double.infinity,
      color: _green,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 28),
            // Image box
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: p.imageColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: p.imageColor.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(p.imageIcon, size: 90, color: p.imageColor),
            ),
            const SizedBox(height: 20),
            // Badges row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (p.isSpecialPrice) ...[
                    _SpecialBadge(),
                    const SizedBox(width: 10),
                  ],
                  _ExpiryChip(daysLeft: p.daysLeft),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Main body content ─────────────────────────────────────────────────────
  Widget _buildBody(DealProduct p, double subtotal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 6),

          // Unit label
          Text(
            p.unitLabel,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),

          // Price card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deal Price',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${p.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Original',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${p.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Discount pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '-${p.discountPct}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Savings banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_rounded, color: _green, size: 20),
                const SizedBox(width: 10),
                Text(
                  'You save Rs.${(p.originalPrice - p.price).toStringAsFixed(0)} on this deal!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quantity selector
          const Text(
            'Quantity',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B1B1B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      onTap: () => setState(
                          () => _quantity = (_quantity - 1).clamp(1, 99)),
                      enabled: _quantity > 1,
                    ),
                    SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      onTap: () => setState(
                          () => _quantity = (_quantity + 1).clamp(1, 99)),
                      enabled: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Subtotal',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 2),
                  Text(
                    'Rs.${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // About section
          const Text(
            'About this product',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B1B)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.description,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6),
          ),
          const SizedBox(height: 24),

          // Info tiles row
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.access_time_rounded,
                  label: 'Expires In',
                  value:
                      '${widget.product.daysLeft} ${widget.product.daysLeft == 1 ? 'Day' : 'Days'}',
                  iconColor: _orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.local_offer_rounded,
                  label: 'Discount',
                  value: '${widget.product.discountPct}% Off',
                  iconColor: _orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Availability',
                  value: 'In Stock',
                  iconColor: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Sticky bottom bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(double subtotal) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Buy Now (outline)
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const MyCartPage()))
                  .then((_) => _refreshCart()),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _green, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'View Cart',
                style: TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Add to Cart (filled)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _adding ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: _green.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _adding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Add to Cart  •  Rs.${subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF9A825)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.local_offer_rounded,
              size: 13, color: Color(0xFFF9A825)),
          SizedBox(width: 5),
          Text(
            'SPECIAL PRICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF9A825),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final int daysLeft;
  const _ExpiryChip({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysLeft <= 2;
    final color = isUrgent ? const Color(0xFFEF6C00) : const Color(0xFFF9A825);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$daysLeft ${daysLeft == 1 ? 'Day' : 'Days'} Left',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1B1B))),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? const Color(0xFF1B8A3D) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
