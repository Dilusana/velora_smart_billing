import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Category Product Model ───────────────────────────────────────────────────

class CategoryProduct {
  final String name;
  final String unit;
  final double price;
  final double? originalPrice;
  final double rating;
  final String? tag; // 'Organic', 'Sale', 'New', etc.
  final Color tagColor;
  final String? imagePath;
  final IconData fallbackIcon;

  const CategoryProduct({
    required this.name,
    required this.unit,
    required this.price,
    this.originalPrice,
    required this.rating,
    this.tag,
    this.tagColor = const Color(0xFF3A5A2A),
    this.imagePath,
    required this.fallbackIcon,
  });
}

// ─── Category Data ────────────────────────────────────────────────────────────

class CategoryData {
  final String title;
  final Color accentColor;
  final Color bgColor;
  final List<CategoryProduct> products;
  final List<String> filters;

  const CategoryData({
    required this.title,
    required this.accentColor,
    required this.bgColor,
    required this.products,
    required this.filters,
  });
}

// ─── All Category Data Map ────────────────────────────────────────────────────

final Map<String, CategoryData> allCategoryData = {
  'Vegetables\n& Fruits': CategoryData(
    title: 'Vegetables & Fruits',
    accentColor: const Color(0xFF3A5A2A),
    bgColor: const Color(0xFFF9FAF0),
    filters: ['Organic', 'Freshness', 'Price: Low to High'],
    products: [
      CategoryProduct(
        name: 'Hass Avocado',
        unit: '500g (Pack of 2)',
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
    ],
  ),
  'Groceries': CategoryData(
    title: 'Groceries',
    accentColor: const Color(0xFF5A4A1E),
    bgColor: const Color(0xFFFBF8F0),
    filters: ['All', 'Deals', 'Price: Low to High'],
    products: [
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
        name: 'Farm Eggs',
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
    ],
  ),
  'Beverages': CategoryData(
    title: 'Beverages',
    accentColor: const Color(0xFF1E3A5A),
    bgColor: const Color(0xFFF0F5FA),
    filters: ['All', 'Cold', 'Hot', 'Price: Low to High'],
    products: [
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
        name: 'Fruit Juice',
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
        name: 'Greek Yogurt Drink',
        unit: '500ml',
        price: 2.80,
        rating: 4.3,
        imagePath: 'assests/yogurt_product.jpg',
        fallbackIcon: Icons.local_drink_rounded,
      ),
      CategoryProduct(
        name: 'Dairy Smoothie',
        unit: '330ml',
        price: 2.50,
        rating: 4.4,
        tag: 'New',
        tagColor: Color(0xFF2563EB),
        imagePath: 'assests/dairy_banner.jpg',
        fallbackIcon: Icons.local_drink_rounded,
      ),
    ],
  ),
  'Household': CategoryData(
    title: 'Household',
    accentColor: const Color(0xFF4A2D5A),
    bgColor: const Color(0xFFF8F0FA),
    filters: ['All', 'Cleaning', 'Kitchen', 'Price: Low to High'],
    products: [
      CategoryProduct(
        name: 'Kitchen Cleaner',
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
        unit: '500ml',
        price: 2.10,
        rating: 4.4,
        imagePath: 'assests/household.png',
        fallbackIcon: Icons.home_rounded,
      ),
      CategoryProduct(
        name: 'Laundry Pods',
        unit: '30 count',
        price: 9.99,
        rating: 4.8,
        tag: 'Popular',
        tagColor: Color(0xFF7C3AED),
        imagePath: 'assests/household.png',
        fallbackIcon: Icons.home_rounded,
      ),
    ],
  ),
  'Chilled\nFoods': CategoryData(
    title: 'Chilled Foods',
    accentColor: const Color(0xFF1E4A5A),
    bgColor: const Color(0xFFF0F8FA),
    filters: ['All', 'Dairy', 'Ready Meals', 'Price: Low to High'],
    products: [
      CategoryProduct(
        name: 'Aged Cheddar',
        unit: '300g Block',
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
        name: 'Farm Eggs',
        unit: 'Dozen',
        price: 5.99,
        rating: 4.6,
        imagePath: 'assests/eggs_product.jpg',
        fallbackIcon: Icons.kitchen_rounded,
      ),
    ],
  ),
  'Frozen\nFoods': CategoryData(
    title: 'Frozen Foods',
    accentColor: const Color(0xFF1A2D5A),
    bgColor: const Color(0xFFF0F3FA),
    filters: ['All', 'Meals', 'Snacks', 'Price: Low to High'],
    products: [
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
        name: 'Berry Blend',
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
        fallbackIcon: Icons.ac_unit_rounded,
      ),
    ],
  ),
};

// ─── Category Screen ──────────────────────────────────────────────────────────

class CategoryScreen extends StatefulWidget {
  final String categoryLabel;

  const CategoryScreen({super.key, required this.categoryLabel});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _selectedFilter = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  final Map<int, int> _quantities = {}; // productIndex -> qty

  late CategoryData _data;

  @override
  void initState() {
    super.initState();
    _data = allCategoryData[widget.categoryLabel] ??
        allCategoryData['Vegetables\n& Fruits']!;
  }

  void _addToCart(int index) {
    final product = _data.products[index];
    setState(() {
      _quantities[index] = (_quantities[index] ?? 0) + 1;
      _cartCount++;
      _cartTotal += product.price;
    });
  }

  List<CategoryProduct> get _filteredProducts {
    final filter = _data.filters[_selectedFilter];
    if (filter == 'All' || filter == 'Freshness') return _data.products;
    if (filter == 'Organic') {
      return _data.products.where((p) => p.tag == 'Organic').toList();
    }
    if (filter == 'Price: Low to High') {
      final sorted = List<CategoryProduct>.from(_data.products);
      sorted.sort((a, b) => a.price.compareTo(b.price));
      return sorted;
    }
    if (filter == 'Sale') {
      return _data.products.where((p) => p.tag == 'Sale').toList();
    }
    // For Cold, Hot, Dairy, etc. — just return all
    return _data.products;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _data.accentColor;
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: _data.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _data.bgColor,
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
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _data.title,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A2D1A),
                              height: 1.1,
                            ),
                          ),
                        ),
                        // Search button
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filter Chips ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _data.filters.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: _data.filters[i],
                              isSelected: _selectedFilter == i,
                              accentColor: accent,
                              onTap: () => setState(() => _selectedFilter = i),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Product Grid ────────────────────────────────────────
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list_off_rounded,
                                  size: 56, color: accent.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'No products in this filter',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: accent.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final product = filtered[i];
                              // find original index for qty tracking
                              final origIdx =
                                  _data.products.indexOf(product);
                              return _ProductCard(
                                product: product,
                                quantity: _quantities[origIdx] ?? 0,
                                accentColor: accent,
                                onAdd: () => _addToCart(origIdx),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),

            // ── Cart Bar ─────────────────────────────────────────────────
            if (_cartCount > 0)
              Positioned(
                bottom: 12,
                left: 20,
                right: 20,
                child: _CartBar(
                  count: _cartCount,
                  total: _cartTotal,
                  accentColor: accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
            if (label.contains('Price')) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final CategoryProduct product;
  final int quantity;
  final Color accentColor;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.accentColor,
    required this.onAdd,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final accent = widget.accentColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image + Tag ──────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: product.imagePath != null
                            ? Image.asset(
                                product.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: const Color(0xFFF5F8F0),
                                  child: Center(
                                    child: Icon(
                                      product.fallbackIcon,
                                      size: 40,
                                      color: accent.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF5F8F0),
                                child: Center(
                                  child: Icon(
                                    product.fallbackIcon,
                                    size: 40,
                                    color: accent.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Tag badge
                    if (product.tag != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.tagColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.tag!,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Details ──────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 13,
                              color: const Color(0xFFFBBF24)),
                          const SizedBox(width: 3),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Name
                      Text(
                        product.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Unit
                      Text(
                        product.unit,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      // If sale — show original price
                      if (product.originalPrice != null)
                        Text(
                          'Rs ${product.originalPrice!.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const Spacer(),
                      // Price + Add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs ${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onAdd,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart Bar ─────────────────────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  final int count;
  final double total;
  final Color accentColor;

  const _CartBar({
    required this.count,
    required this.total,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart count badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Items in cart',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Total
          Text(
            'Rs ${total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // Checkout arrow
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
