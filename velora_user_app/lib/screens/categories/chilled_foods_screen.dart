import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF0E6A7A);
const _bg = Color(0xFFEFF9FB);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'Aged Cheddar',
    unit: '300g block',
    price: 5.50,
    rating: 4.9,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/cheese_special.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Greek Yogurt',
    unit: '400g pot',
    price: 3.80,
    originalPrice: 4.50,
    rating: 4.7,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/yogurt_product.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Organic Whole Milk',
    unit: '1 Litre',
    price: 4.50,
    rating: 4.8,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/milk_product.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Free Range Eggs',
    unit: 'Dozen',
    price: 5.99,
    rating: 4.6,
    imagePath: 'assests/eggs_product.jpg',
    fallbackIcon: Icons.egg_rounded,
  ),
  CategoryProduct(
    name: 'Butter',
    unit: '250g block',
    price: 3.20,
    rating: 4.5,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/dairy_banner.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Cream Cheese',
    unit: '200g tub',
    price: 2.80,
    originalPrice: 3.50,
    rating: 4.4,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/cheese_special.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Sour Cream',
    unit: '300ml pot',
    price: 2.50,
    rating: 4.3,
    imagePath: 'assests/yogurt_product.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
  CategoryProduct(
    name: 'Skimmed Milk',
    unit: '2 Litres',
    price: 5.20,
    rating: 4.5,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/milk_product.jpg',
    fallbackIcon: Icons.kitchen_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Dairy',
  'Cheese',
  'Organic',
  'Price: Low to High',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChilledFoodsScreen extends StatefulWidget {
  const ChilledFoodsScreen({super.key});

  @override
  State<ChilledFoodsScreen> createState() => _ChilledFoodsScreenState();
}

class _ChilledFoodsScreenState extends State<ChilledFoodsScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All') return _products;
    if (f == 'Dairy') {
      return _products
          .where((p) =>
              p.name.contains('Milk') ||
              p.name.contains('Yogurt') ||
              p.name.contains('Butter') ||
              p.name.contains('Cream') ||
              p.name.contains('Eggs'))
          .toList();
    }
    if (f == 'Cheese') {
      return _products.where((p) => p.name.contains('Cheese') || p.name.contains('Cheddar')).toList();
    }
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
                  title: 'Chilled Foods',
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
                              'assests/chilledfood.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF064E5A), Color(0xFF0E6A7A)],
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
                                    _accent.withValues(alpha: 0.82),
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
                                Text('Fresh & Chilled,',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Always Perfect',
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
                                color: const Color(0xFF22D3EE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Dairy Specials',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0A3040))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
