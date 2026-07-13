import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';
import 'deal_product_detail_page.dart';
import 'my_cart_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

enum DealSort { newest, priceAsc, priceDesc, discount }

class DealProduct {
  final String title;
  final String description;
  final String unitLabel;    // e.g. "Rs.32 /100g"
  final double price;        // selling price
  final double originalPrice;
  final int discountPct;
  final int daysLeft;
  final bool isSpecialPrice;
  final IconData imageIcon;
  final Color imageColor;
  final List<String> categories;

  const DealProduct({
    required this.title,
    required this.description,
    required this.unitLabel,
    required this.price,
    required this.originalPrice,
    required this.discountPct,
    required this.daysLeft,
    this.isSpecialPrice = false,
    required this.imageIcon,
    required this.imageColor,
    required this.categories,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sample catalog
// ─────────────────────────────────────────────────────────────────────────────

const List<DealProduct> _kDeals = [
  DealProduct(
    title: 'Organic Fuji Apples',
    description: 'Sweet, crispy pesticide-free Fuji apples hand-picked at...',
    unitLabel: 'Rs.32 /100g',
    price: 320,
    originalPrice: 480,
    discountPct: 33,
    daysLeft: 1,
    imageIcon: Icons.apple_rounded,
    imageColor: Color(0xFFDB4343),
    categories: ['Vegetables & Fruits'],
  ),
  DealProduct(
    title: 'Cold Pressed Orange Juice',
    description: '100% cold-pressed orange juice with no added sugar,...',
    unitLabel: 'Rs.22 /100ml',
    price: 220,
    originalPrice: 310,
    discountPct: 29,
    daysLeft: 5,
    isSpecialPrice: true,
    imageIcon: Icons.local_drink_rounded,
    imageColor: Color(0xFFF57C00),
    categories: ['Beverages'],
  ),
  DealProduct(
    title: 'Margherita Frozen Pizza',
    description: 'Classic Margherita on a hand-stretched stone-baked...',
    unitLabel: 'Rs.144 /100g',
    price: 650,
    originalPrice: 850,
    discountPct: 24,
    daysLeft: 6,
    imageIcon: Icons.local_pizza_rounded,
    imageColor: Color(0xFFBF360C),
    categories: ['Frozen Foods'],
  ),
  DealProduct(
    title: 'Fresh Strawberries',
    description: 'Hand-picked farm-fresh strawberries, naturally sweet,...',
    unitLabel: 'Rs.90 /100g',
    price: 450,
    originalPrice: 580,
    discountPct: 22,
    daysLeft: 1,
    imageIcon: Icons.spa_rounded,
    imageColor: Color(0xFFE53935),
    categories: ['Vegetables & Fruits'],
  ),
  DealProduct(
    title: 'Greek Yogurt Tub',
    description: 'Rich creamy Greek yogurt, high protein, no preservatives.',
    unitLabel: 'Rs.18 /100g',
    price: 290,
    originalPrice: 390,
    discountPct: 26,
    daysLeft: 3,
    imageIcon: Icons.icecream_rounded,
    imageColor: Color(0xFF7B1FA2),
    categories: ['Chilled Foods'],
  ),
  DealProduct(
    title: 'Whole Grain Bread Loaf',
    description: 'Freshly baked whole grain loaf, preservative-free,...',
    unitLabel: 'Rs.12 /100g',
    price: 185,
    originalPrice: 240,
    discountPct: 23,
    daysLeft: 2,
    imageIcon: Icons.bakery_dining_rounded,
    imageColor: Color(0xFF8D6E63),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Raw Honey Jar',
    description: 'Pure unfiltered raw honey sourced from local beekeepers.',
    unitLabel: 'Rs.95 /100g',
    price: 760,
    originalPrice: 950,
    discountPct: 20,
    daysLeft: 7,
    isSpecialPrice: true,
    imageIcon: Icons.emoji_nature_rounded,
    imageColor: Color(0xFFF9A825),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Free-Range Eggs (12)',
    description: 'Farm-fresh free-range eggs, rich in omega-3 fatty acids.',
    unitLabel: 'Rs.28 /egg',
    price: 340,
    originalPrice: 430,
    discountPct: 21,
    daysLeft: 4,
    imageIcon: Icons.egg_rounded,
    imageColor: Color(0xFFFF8F00),
    categories: ['Chilled Foods', 'Grocery'],
  ),
  DealProduct(
    title: 'Cheddar Cheese Block',
    description: 'Aged sharp cheddar cheese — perfect for cooking or snacks.',
    unitLabel: 'Rs.120 /100g',
    price: 620,
    originalPrice: 800,
    discountPct: 23,
    daysLeft: 5,
    imageIcon: Icons.kitchen_rounded,
    imageColor: Color(0xFFD32F2F),
    categories: ['Chilled Foods'],
  ),
  DealProduct(
    title: 'Basmati Rice (5kg)',
    description: 'Premium long-grain basmati rice, aged for superior aroma.',
    unitLabel: 'Rs.28 /100g',
    price: 1380,
    originalPrice: 1700,
    discountPct: 19,
    daysLeft: 8,
    imageIcon: Icons.rice_bowl_rounded,
    imageColor: Color(0xFF6D4C41),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Virgin Coconut Oil',
    description: 'Cold-pressed pure virgin coconut oil — unrefined & natural.',
    unitLabel: 'Rs.85 /100ml',
    price: 680,
    originalPrice: 890,
    discountPct: 24,
    daysLeft: 10,
    isSpecialPrice: true,
    imageIcon: Icons.local_fire_department_rounded,
    imageColor: Color(0xFF43A047),
    categories: ['Household'],
  ),
  DealProduct(
    title: 'Almonds (250g)',
    description: 'California-grown whole almonds, roasted with light sea salt.',
    unitLabel: 'Rs.160 /100g',
    price: 400,
    originalPrice: 520,
    discountPct: 23,
    daysLeft: 12,
    imageIcon: Icons.eco_rounded,
    imageColor: Color(0xFF795548),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Sparkling Water 6-Pack',
    description: 'Natural mineral sparkling water — zero calories, refreshing.',
    unitLabel: 'Rs.22 /100ml',
    price: 260,
    originalPrice: 340,
    discountPct: 24,
    daysLeft: 9,
    imageIcon: Icons.water_drop_rounded,
    imageColor: Color(0xFF1976D2),
    categories: ['Beverages'],
  ),
  DealProduct(
    title: 'Dark Chocolate Bar',
    description: '72% cacao dark chocolate — rich, velvety, antioxidant-rich.',
    unitLabel: 'Rs.80 /100g',
    price: 240,
    originalPrice: 320,
    discountPct: 25,
    daysLeft: 14,
    imageIcon: Icons.lunch_dining_rounded,
    imageColor: Color(0xFF4E342E),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Pasta (Penne) 500g',
    description: 'Italian durum wheat semolina pasta — al dente perfection.',
    unitLabel: 'Rs.16 /100g',
    price: 80,
    originalPrice: 110,
    discountPct: 27,
    daysLeft: 6,
    imageIcon: Icons.dinner_dining_rounded,
    imageColor: Color(0xFFFBC02D),
    categories: ['Grocery'],
  ),
  DealProduct(
    title: 'Oat Milk (1L)',
    description: 'Barista-blend oat milk — creamy, dairy-free, fortified.',
    unitLabel: 'Rs.24 /100ml',
    price: 240,
    originalPrice: 310,
    discountPct: 23,
    daysLeft: 3,
    isSpecialPrice: true,
    imageIcon: Icons.local_cafe_rounded,
    imageColor: Color(0xFF6D9E61),
    categories: ['Beverages', 'Chilled Foods'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page widget
// ─────────────────────────────────────────────────────────────────────────────

class AllDealsPage extends StatefulWidget {
  final CategoryItem? category;

  const AllDealsPage({super.key, this.category});

  @override
  State<AllDealsPage> createState() => _AllDealsPageState();
}

class _AllDealsPageState extends State<AllDealsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  DealSort _sort = DealSort.newest;
  int _cartCount = 0;

  static const Color _green = Color(0xFF1B8A3D);

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshCart() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart(DealProduct p) async {
    final item = CartItem(
      category: 'Deals',
      title: p.title,
      description: p.description,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    await _refreshCart();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.title} added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  bool _matchesCategory(DealProduct product) {
    final selected = widget.category?.title;
    return selected == null || product.categories.contains(selected);
  }

  List<DealProduct> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _kDeals.where(_matchesCategory).toList();

    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sort) {
      case DealSort.newest:
        break; // keep original order
      case DealSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case DealSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case DealSort.discount:
        list.sort((a, b) => b.discountPct.compareTo(a.discountPct));
        break;
    }
    return list;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final products = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCountSortBar(products.length),
          Expanded(
            child: products.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) => _DealCard(
                      product: products[i],
                      onAddToCart: () => _addToCart(products[i]),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DealProductDetailPage(
                            product: products[i],
                          ),
                        ),
                      ).then((_) => _refreshCart()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final title = widget.category?.title ?? 'All Deals';

    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Cart badge
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            hintText: widget.category == null
                ? 'Search products, categories, offers...'
                : 'Search ${widget.category!.title.toLowerCase()}',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  // ── Count + Sort bar ─────────────────────────────────────────────────────

  Widget _buildCountSortBar(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const TextSpan(
                  text: ' products found',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const Spacer(),
          _SortDropdown(
            value: _sort,
            onChanged: (v) => setState(() => _sort = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No deals found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  final DealSort value;
  final ValueChanged<DealSort> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  static const _labels = {
    DealSort.newest: 'Newest',
    DealSort.priceAsc: 'Price ↑',
    DealSort.priceDesc: 'Price ↓',
    DealSort.discount: 'Top Deals',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1B8A3D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DealSort>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Color(0xFF1B8A3D)),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B8A3D)),
          items: DealSort.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(_labels[s]!),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deal card
// ─────────────────────────────────────────────────────────────────────────────

class _DealCard extends StatelessWidget {
  final DealProduct product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _DealCard({
    required this.product,
    required this.onAddToCart,
    required this.onTap,
  });

  static const Color _green = Color(0xFF1B8A3D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product image ──────────────────────────────────────────────
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: product.imageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(product.imageIcon,
                    size: 42, color: product.imageColor),
              ),
              const SizedBox(width: 14),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Special price badge
                    if (product.isSpecialPrice) ...[
                      _SpecialPriceBadge(),
                      const SizedBox(height: 4),
                    ],

                    // Title
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price row
                    Row(
                      children: [
                        Text(
                          'Rs.${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rs.${product.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DiscountBadge(pct: product.discountPct),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Unit label
                    Text(
                      product.unitLabel,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Right column: timer + arrow ────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ExpiryBadge(daysLeft: product.daysLeft),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onAddToCart,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF9E9E9E), size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialPriceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF9A825), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.local_offer_rounded,
              size: 12, color: Color(0xFFF9A825)),
          SizedBox(width: 4),
          Text(
            'SPECIAL PRICE',
            style: TextStyle(
              fontSize: 10,
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

class _DiscountBadge extends StatelessWidget {
  final int pct;
  const _DiscountBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF6C00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '-$pct%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int daysLeft;
  const _ExpiryBadge({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysLeft <= 2;
    const urgentColor = Color(0xFFEF6C00);
    const normalColor = Color(0xFFF9A825);
    final color = isUrgent ? urgentColor : normalColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isUrgent ? urgentColor : normalColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Icon(Icons.access_time_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '$daysLeft ${daysLeft == 1 ? 'Day' : 'Days'} Left',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
