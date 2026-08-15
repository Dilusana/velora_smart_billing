import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF92610A);
const _bg = Color(0xFFFBF8F0);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'Artisan Sourdough',
    unit: 'Per loaf',
    price: 6.00,
    rating: 4.8,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/sourdough_product.jpg',
    fallbackIcon: Icons.breakfast_dining_rounded,
  ),
  CategoryProduct(
    name: 'Wildflower Honey',
    unit: '500ml jar',
    price: 8.50,
    originalPrice: 10.99,
    rating: 4.9,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/honey_product.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Free Range Eggs',
    unit: 'Dozen',
    price: 5.99,
    rating: 4.7,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/eggs_product.jpg',
    fallbackIcon: Icons.egg_rounded,
  ),
  CategoryProduct(
    name: 'Greek Yogurt',
    unit: '400g pot',
    price: 3.80,
    rating: 4.6,
    imagePath: 'assests/yogurt_product.jpg',
    fallbackIcon: Icons.icecream_rounded,
  ),
  CategoryProduct(
    name: 'Rolled Oats',
    unit: '500g bag',
    price: 2.20,
    rating: 4.5,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/grocery.png',
    fallbackIcon: Icons.breakfast_dining_rounded,
  ),
  CategoryProduct(
    name: 'Pasta Fusilli',
    unit: '500g pack',
    price: 1.80,
    originalPrice: 2.30,
    rating: 4.4,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/grocery.png',
    fallbackIcon: Icons.restaurant_rounded,
  ),
  CategoryProduct(
    name: 'Basmati Rice',
    unit: '1kg bag',
    price: 3.50,
    rating: 4.7,
    imagePath: 'assests/grocery.png',
    fallbackIcon: Icons.restaurant_rounded,
  ),
  CategoryProduct(
    name: 'Canned Chickpeas',
    unit: '400g tin',
    price: 1.20,
    rating: 4.3,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/grocery.png',
    fallbackIcon: Icons.restaurant_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Organic',
  'Sale',
  'New',
  'Price: Low to High',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All') return _products;
    if (f == 'Organic') return _products.where((p) => p.tag == 'Organic').toList();
    if (f == 'Sale') return _products.where((p) => p.tag == 'Sale').toList();
    if (f == 'New') return _products.where((p) => p.tag == 'New').toList();
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
                const CategoryAppBar(
                  title: 'Groceries',
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
                              'assests/grocery.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF5A3A0A), Color(0xFF92610A)],
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
                                    _accent.withValues(alpha: 0.80),
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
                                Text('Your Weekly',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Essentials',
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
                                color: const Color(0xFFFBBF24),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Members Save More',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1000))),
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

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      '${filtered.length} products',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280)),
                    ),
                  ),
                ),

                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: _emptyState(),
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
            if (_cartCount > 0)
              Positioned(
                bottom: 12,
                left: 20,
                right: 20,
                child: CategoryCartBar(
                    count: _cartCount, total: _cartTotal, accentColor: _accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded,
                size: 56, color: _accent.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No products in this filter',
                style: GoogleFonts.outfit(
                    fontSize: 15, color: _accent.withValues(alpha: 0.5))),
          ],
        ),
      );
}
