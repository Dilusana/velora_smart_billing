import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF1E3A8A);
const _bg = Color(0xFFF0F3FA);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'Frozen Spinach',
    unit: '500g bag',
    price: 2.50,
    rating: 4.5,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
  CategoryProduct(
    name: 'Mixed Vegetables',
    unit: '750g bag',
    price: 3.20,
    originalPrice: 3.99,
    rating: 4.6,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
  CategoryProduct(
    name: 'Mixed Berry Blend',
    unit: '500g bag',
    price: 4.50,
    rating: 4.7,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
  CategoryProduct(
    name: 'Fish Fillets',
    unit: '400g pack',
    price: 6.99,
    rating: 4.4,
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.set_meal_rounded,
  ),
  CategoryProduct(
    name: 'Chicken Breast',
    unit: '600g pack',
    price: 7.50,
    rating: 4.6,
    tag: 'Popular',
    tagColor: Color(0xFF7C3AED),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.set_meal_rounded,
  ),
  CategoryProduct(
    name: 'Edamame Beans',
    unit: '400g bag',
    price: 3.50,
    originalPrice: 4.20,
    rating: 4.5,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
  CategoryProduct(
    name: 'Frozen Peas',
    unit: '1kg bag',
    price: 2.80,
    rating: 4.4,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
  CategoryProduct(
    name: 'Sweetcorn',
    unit: '500g bag',
    price: 1.99,
    rating: 4.3,
    imagePath: 'assests/frozenfoods.jpeg',
    fallbackIcon: Icons.ac_unit_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Vegetables',
  'Meat & Fish',
  'Organic',
  'Price: Low to High',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class FrozenFoodsScreen extends StatefulWidget {
  const FrozenFoodsScreen({super.key});

  @override
  State<FrozenFoodsScreen> createState() => _FrozenFoodsScreenState();
}

class _FrozenFoodsScreenState extends State<FrozenFoodsScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All') return _products;
    if (f == 'Vegetables') {
      return _products
          .where((p) =>
              p.name.contains('Spinach') ||
              p.name.contains('Vegetables') ||
              p.name.contains('Peas') ||
              p.name.contains('Sweetcorn') ||
              p.name.contains('Edamame'))
          .toList();
    }
    if (f == 'Meat & Fish') {
      return _products
          .where((p) =>
              p.name.contains('Fish') || p.name.contains('Chicken'))
          .toList();
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
                  title: 'Frozen Foods',
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
                              'assests/frozenfoods.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0A1A4A), Color(0xFF1E3A8A)],
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
                                    _accent.withValues(alpha: 0.85),
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
                                Text('Locked in',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Freshness & Flavour',
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
                                color: const Color(0xFF60A5FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('No Preservatives',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0A1830))),
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
