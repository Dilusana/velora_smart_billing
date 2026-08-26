import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'my_cart_page.dart';
import 'product_model.dart';

/// Full-screen product detail page reached by tapping a product card.
class DealProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const DealProductDetailPage({super.key, required this.product});

  @override
  State<DealProductDetailPage> createState() => _DealProductDetailPageState();
}

class _DealProductDetailPageState extends State<DealProductDetailPage> {
  int _quantity = 1;
  int _cartCount = 0;
  bool _adding = false;
  String? _resolvedCategoryName;

  static const Color _green = AppColors.brand;
  static const Color _orange = AppColors.cta;
  static const Color _bg = AppColors.background;

  @override
  void initState() {
    super.initState();
    _refreshCart();
    _resolveCategoryName();
  }

  /// Resolves the category name from Firestore if the product's category field
  /// looks like a Firestore document ID rather than a human-readable name.
  Future<void> _resolveCategoryName() async {
    final p = widget.product;
    final cat = p.category;
    final catId = p.categoryId;

    // If category is already a readable name (contains spaces, letters, &, etc.), use it directly
    if (cat.isNotEmpty && !_looksLikeDocId(cat)) {
      setState(() => _resolvedCategoryName = cat);
      return;
    }

    // Try to look up the category name from Firestore using categoryId or category (if it's an ID)
    final idToLookup = catId.isNotEmpty ? catId : cat;
    if (idToLookup.isEmpty) {
      setState(() => _resolvedCategoryName = 'General');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(idToLookup)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final name = (data['name'] ?? data['title'] ?? '').toString();
        if (name.isNotEmpty && mounted) {
          setState(() => _resolvedCategoryName = name);
          return;
        }
      }
    } catch (_) {
      // Firestore unavailable — fallback
    }

    // Fallback: use whatever we have
    if (mounted) {
      setState(() => _resolvedCategoryName = cat.isNotEmpty ? cat : 'General');
    }
  }

  /// Heuristic: a string that is 15+ chars, has no spaces, and is alphanumeric
  /// is likely a Firestore auto-generated document ID.
  bool _looksLikeDocId(String value) {
    if (value.length < 15) return false;
    if (value.contains(' ')) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }

  Future<void> _refreshCart() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final item = CartItem(
      productId: widget.product.id,
      category: widget.product.category.isNotEmpty ? widget.product.category : 'General',
      title: widget.product.name,
      description: widget.product.description,
      price: widget.product.price,
      quantity: _quantity,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    await _refreshCart();
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} × $_quantity added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

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

  Widget _buildImageHero(ProductModel p) {
    final bool hasWebImage = p.isWebImage;
    final bool hasAssetImage = p.isAssetImage;

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
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: hasWebImage
                    ? Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, size: 140, color: _green),
                      )
                    : hasAssetImage
                        ? Image.asset(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, size: 140, color: _green),
                          )
                        : const Icon(Icons.shopping_bag_rounded, size: 140, color: _green),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductModel p, double subtotal) {
    final unitText = p.unit.isNotEmpty ? 'Per ${p.unit}' : 'Unit Price';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unitText,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
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
                    const Text('Price',
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quantity',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B1B1B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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
                      enabled: _quantity < 99,
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
          const Text(
            'About this product',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B1B)),
          ),
          const SizedBox(height: 8),
          Text(
            p.description.isNotEmpty ? p.description : 'No additional description available.',
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.category_rounded,
                  label: 'Category',
                  value: _resolvedCategoryName ?? 'Loading...',
                  iconColor: _orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Status',
                  value: p.status.toUpperCase(),
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

  Widget _buildBottomBar(double subtotal) {
    final bool canAdd = widget.product.stock > 0;

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
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_adding || !canAdd) ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: Colors.grey.shade400,
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
                      canAdd
                          ? 'Add to Cart  •  Rs.${subtotal.toStringAsFixed(0)}'
                          : 'Out of Stock',
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
