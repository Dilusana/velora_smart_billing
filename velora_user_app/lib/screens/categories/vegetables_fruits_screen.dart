import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF3A5A2A);
const _bg = Color(0xFFF5F9EE);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'Hass Avocado',
    unit: '500g • Pack of 2',
    price: 3.50,
    rating: 4.8,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/veg_fruits.png',
    fallbackIcon: Icons.eco_rounded,
  ),
  CategoryProduct(
    name: 'Vine Tomatoes',
    unit: '1kg Bundle',
    price: 2.10,
    originalPrice: 2.70,
    rating: 4.9,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/tomatoes_product.jpg',
    fallbackIcon: Icons.eco_rounded,
  ),
  CategoryProduct(
    name: 'Baby Spinach',
    unit: '250g Pre-washed',
    price: 3.25,
    rating: 4.7,
    imagePath: 'assests/spinach_product.jpg',
    fallbackIcon: Icons.eco_rounded,
  ),
  CategoryProduct(
    name: 'Bunch Carrots',
    unit: 'approx. 600g',
    price: 2.10,
    rating: 4.5,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/veg_fruits.png',
    fallbackIcon: Icons.eco_rounded,
  ),
  CategoryProduct(
    name: 'Gala Apples',
    unit: 'Per kg',
    price: 3.80,
    originalPrice: 4.50,
    rating: 4.6,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/apples_banner.jpg',
    fallbackIcon: Icons.apple_rounded,
  ),
  CategoryProduct(
    name: 'Premium Bananas',
    unit: 'Per kg',
    price: 2.20,
    rating: 4.4,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/bananas_product.jpg',
    fallbackIcon: Icons.apple_rounded,
  ),
  CategoryProduct(
    name: 'Fresh Cucumber',
    unit: 'Each',
    price: 0.90,
    rating: 4.3,
    imagePath: 'assests/veg_fruits.png',
    fallbackIcon: Icons.eco_rounded,
  ),
  CategoryProduct(
    name: 'Mixed Salad Leaves',
    unit: '120g Bag',
    price: 2.50,
    rating: 4.6,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/fruits_banner.jpg',
    fallbackIcon: Icons.eco_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Organic',
  'Freshness',
  'Price: Low to High',
  'Sale',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class VegetablesFruitsScreen extends StatefulWidget {
  const VegetablesFruitsScreen({super.key});

  @override
  State<VegetablesFruitsScreen> createState() => _VegetablesFruitsScreenState();
}

class _VegetablesFruitsScreenState extends State<VegetablesFruitsScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All' || f == 'Freshness') return _products;
    if (f == 'Organic') return _products.where((p) => p.tag == 'Organic').toList();
    if (f == 'Sale') return _products.where((p) => p.tag == 'Sale').toList();
    if (f == 'Price: Low to High') {
      return List.of(_products)..sort((a, b) => a.price.compareTo(b.price));
    }
    return _products;
  }

  void _add(int origIdx) {
    setState(() {
      _quantities[origIdx] = (_quantities[origIdx] ?? 0) + 1;
      _cartCount++;
      _cartTotal += _products[origIdx].price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ─────────────────────────────────────────────
                const CategoryAppBar(
                  title: 'Vegetables & Fruits',
                  accentColor: _accent,
                ),

                // ── Hero Banner ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: Image.asset(
                              'assests/vegetables_banner.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF2D5A1E), Color(0xFF4A8A2A)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    _accent.withValues(alpha: 0.75),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            top: 0,
                            bottom: 0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Farm Fresh,',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Delivered Daily',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCEE847),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Up to 30% off',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A2D1A))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Filter Chips ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _filters.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryFilterChip(
                              label: _filters[i],
                              isSelected: _selectedFilter == i,
                              accentColor: _accent,
                              hasDropdown: _filters[i].contains('Price'),
                              onTap: () => setState(() => _selectedFilter = i),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Count label ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      '${filtered.length} products',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                // ── Grid ─────────────────────────────────────────────────
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(accentColor: _accent),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.64,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final p = filtered[i];
                              final orig = _products.indexOf(p);
                              return CategoryProductCard(
                                product: p,
                                accentColor: _accent,
                                onAdd: () => _add(orig),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),

            // ── Cart Bar ───────────────────────────────────────────────
            if (_cartCount > 0)
              Positioned(
                bottom: 12,
                left: 20,
                right: 20,
                child: CategoryCartBar(
                  count: _cartCount,
                  total: _cartTotal,
                  accentColor: _accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  const _EmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded,
              size: 56, color: accentColor.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No products in this filter',
            style: GoogleFonts.outfit(
                fontSize: 15, color: accentColor.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
