import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_category_widgets.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const _accent = Color(0xFF5B21B6);
const _bg = Color(0xFFF8F5FF);

// ─── Product Data ─────────────────────────────────────────────────────────────

const List<CategoryProduct> _products = [
  CategoryProduct(
    name: 'All-Purpose Cleaner',
    unit: '750ml Spray',
    price: 4.99,
    rating: 4.5,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.home_rounded,
  ),
  CategoryProduct(
    name: 'Multi-Surface Wipes',
    unit: 'Pack of 80',
    price: 3.50,
    originalPrice: 4.20,
    rating: 4.7,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.home_rounded,
  ),
  CategoryProduct(
    name: 'Dish Soap',
    unit: '500ml bottle',
    price: 2.10,
    rating: 4.4,
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.home_rounded,
  ),
  CategoryProduct(
    name: 'Laundry Pods',
    unit: '30 count pack',
    price: 9.99,
    rating: 4.8,
    tag: 'Popular',
    tagColor: Color(0xFF7C3AED),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.local_laundry_service_rounded,
  ),
  CategoryProduct(
    name: 'Toilet Cleaner',
    unit: '500ml bottle',
    price: 2.80,
    rating: 4.3,
    tag: 'Sale',
    tagColor: Color(0xFFEF4444),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.home_rounded,
    originalPrice: 3.50,
  ),
  CategoryProduct(
    name: 'Fabric Softener',
    unit: '1L bottle',
    price: 5.20,
    rating: 4.6,
    tag: 'Organic',
    tagColor: Color(0xFF3A5A2A),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.local_laundry_service_rounded,
  ),
  CategoryProduct(
    name: 'Bin Bags',
    unit: '30 pack',
    price: 3.20,
    rating: 4.2,
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.delete_rounded,
  ),
  CategoryProduct(
    name: 'Glass Cleaner',
    unit: '500ml Spray',
    price: 3.80,
    rating: 4.5,
    tag: 'New',
    tagColor: Color(0xFF2563EB),
    imagePath: 'assests/household.png',
    fallbackIcon: Icons.window_rounded,
  ),
];

const List<String> _filters = [
  'All',
  'Cleaning',
  'Laundry',
  'Sale',
  'Price: Low to High',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {};

  List<CategoryProduct> get _filtered {
    final f = _filters[_selectedFilter];
    if (f == 'All') return _products;
    if (f == 'Cleaning') {
      return _products
          .where((p) =>
              p.name.contains('Cleaner') ||
              p.name.contains('Wipes') ||
              p.name.contains('Dish') ||
              p.name.contains('Glass') ||
              p.name.contains('Toilet'))
          .toList();
    }
    if (f == 'Laundry') {
      return _products
          .where((p) =>
              p.name.contains('Laundry') || p.name.contains('Fabric'))
          .toList();
    }
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
                const CategoryAppBar(
                  title: 'Household',
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
                              'assests/household.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3B0FAA), Color(0xFF5B21B6)],
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
                                Text('Home Sweet',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Clean Home',
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
                                color: const Color(0xFFA78BFA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Eco-Friendly Picks',
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
