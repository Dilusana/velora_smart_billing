import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF1A4A7A);
const _bg = Color(0xFFF0F5FA);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'Organic Whole Milk',
    unit: '1 Litre',
    price: 4.50,
    rating: 4.8,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/milk_product.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Fresh Orange Juice',
    unit: '1L Carton',
    price: 3.20,
    originalPrice: 3.99,
    rating: 4.5,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/fruits_banner.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Sparkling Water',
    unit: '6 × 500ml',
    price: 2.80,
    rating: 4.3,
    imagePath: 'assests/beverages.png',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Fruit Smoothie',
    unit: '330ml bottle',
    price: 2.50,
    rating: 4.4,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/dairy_banner.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Coconut Water',
    unit: '500ml',
    price: 2.10,
    rating: 4.6,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/beverages.png',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Almond Milk',
    unit: '1 Litre',
    price: 3.80,
    originalPrice: 4.50,
    rating: 4.7,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/milk_product.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Green Tea',
    unit: '20 bags',
    price: 2.99,
    rating: 4.5,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/beverages.png',
    fallbackIcon: Icons.local_drink_rounded,
  ),
  CategoryProduct(
    name: 'Oat Milk',
    unit: '1 Litre',
    price: 3.50,
    rating: 4.4,
    imagePath: 'assests/milk_product.jpg',
    fallbackIcon: Icons.local_drink_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Cold',
  'Hot',
  'Organic',
  'Price: Low to High',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class BeveragesScreen extends StatefulWidget {
  const BeveragesScreen({super.key});

  @override
  State<BeveragesScreen> createState() => _BeveragesScreenState();
}

class _BeveragesScreenState extends State<BeveragesScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All' || f == 'Cold' || f == 'Hot') return _products;
    if (f == 'Organic') return _products.where((p) => p.tag == 'Organic').toList();
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
                  title: 'Beverages',
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
                              'assests/beverages.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0A2A5A), Color(0xFF1A4A7A)],
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
                                Text('Stay Refreshed,',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Stay Hydrated',
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
                                color: const Color(0xFF38BDF8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Buy 3 Get 1 Free',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
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
                    ? SliverFillRemaining(child: _emptyState())
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
