import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import 'cart_screen.dart';
import '../widgets/product_quantity_modal.dart';



// ─── Category Product Model ───────────────────────────────────────────────────

class CategoryProduct {
  final String name;
  final String unit;
  final double price;
  final double? originalPrice;
  final double rating;
  final String? tag; // 'Featured', 'Sale', 'New', etc.
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
    filters: ['All', 'Organic', 'Freshness', 'Price: Low to High'],
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

  Color _getAccentColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('veg') || lower.contains('fruit')) return const Color(0xFF3A5A2A);
    if (lower.contains('groc')) return const Color(0xFF5A4A1E);
    if (lower.contains('beverag')) return const Color(0xFF1E3A5A);
    if (lower.contains('house')) return const Color(0xFF4A2D5A);
    if (lower.contains('chill')) return const Color(0xFF1E4A5A);
    if (lower.contains('frozen')) return const Color(0xFF1A2D5A);
    if (lower.contains('electr')) return const Color(0xFF2563EB);
    if (lower.contains('cloth')) return const Color(0xFF7C3AED);
    if (lower.contains('beauty')) return const Color(0xFFDB2777);
    return const Color(0xFF1F2937);
  }

  Color _getBgColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('veg') || lower.contains('fruit')) return const Color(0xFFF9FAF0);
    if (lower.contains('groc')) return const Color(0xFFFBF8F0);
    if (lower.contains('beverag')) return const Color(0xFFF0F5FA);
    if (lower.contains('house')) return const Color(0xFFF8F0FA);
    if (lower.contains('chill')) return const Color(0xFFF0F8FA);
    if (lower.contains('frozen')) return const Color(0xFFF0F3FA);
    if (lower.contains('electr')) return const Color(0xFFEFF6FF);
    if (lower.contains('cloth')) return const Color(0xFFF5F3FF);
    if (lower.contains('beauty')) return const Color(0xFFFDF2F8);
    return const Color(0xFFF9FAFB);
  }

  CategoryData _resolveCategoryData(List<CategoryModel> dbCategories) {
    final cleanLabel = widget.categoryLabel.replaceAll('\n', ' ').trim();
    if (cleanLabel.isEmpty || cleanLabel.toLowerCase() == 'all' || cleanLabel.toLowerCase() == 'all products') {
      return const CategoryData(
        title: 'All Products',
        accentColor: Color(0xFF1E3A5A),
        bgColor: Color(0xFFF0F5FA),
        products: [],
        filters: ['All', 'Price: Low to High'],
      );
    }

    // Try matching in Firestore categories list
    for (final cat in dbCategories) {
      final catIdClean = cat.id.trim().toLowerCase();
      final catTitleClean = cat.title.trim().replaceAll('\n', ' ').toLowerCase();
      if (catIdClean == cleanLabel.toLowerCase() || catTitleClean == cleanLabel.toLowerCase()) {
        return CategoryData(
          title: cat.title,
          accentColor: _getAccentColor(cat.title),
          bgColor: _getBgColor(cat.title),
          products: const [],
          filters: const ['All', 'Price: Low to High'],
        );
      }
    }

    // Try matching in allCategoryData map
    for (final entry in allCategoryData.entries) {
      final keyClean = entry.key.replaceAll('\n', ' ').trim();
      if (entry.key == widget.categoryLabel ||
          keyClean.toLowerCase() == cleanLabel.toLowerCase() ||
          entry.value.title.toLowerCase() == cleanLabel.toLowerCase()) {
        return CategoryData(
          title: entry.value.title,
          accentColor: entry.value.accentColor,
          bgColor: entry.value.bgColor,
          products: entry.value.products,
          filters: const ['All', 'Price: Low to High'],
        );
      }
    }

    return CategoryData(
      title: cleanLabel,
      accentColor: _getAccentColor(cleanLabel),
      bgColor: _getBgColor(cleanLabel),
      products: const [],
      filters: const ['All', 'Price: Low to High'],
    );
  }

  void _addToCartProduct(CategoryProduct product, int index, String categoryTitle) {
    final String pId = 'prod_${product.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    ProductQuantityModal.show(
      context,
      productId: pId,
      productName: product.name,
      category: categoryTitle,
      unit: product.unit,
      basePrice: product.price,
      imageUrl: product.imagePath ?? '',
      fallbackIcon: product.fallbackIcon,
    );
  }

  List<CategoryProduct> _getFilteredProductsList(List<CategoryProduct> products, List<String> filters) {
    if (_selectedFilter >= filters.length) return products;
    final filter = filters[_selectedFilter];
    if (filter == 'All') return products;
    if (filter == 'Price: Low to High') {
      final sorted = List<CategoryProduct>.from(products);
      sorted.sort((a, b) => a.price.compareTo(b.price));
      return sorted;
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryModel>>(
      stream: CategoryRepository.instance.getCategoriesStream(),
      builder: (context, catSnapshot) {
        final dbCategories = catSnapshot.data ?? [];
        final categoryData = _resolveCategoryData(dbCategories);
        final accent = categoryData.accentColor;

        return StreamBuilder<List<ProductModel>>(
          stream: ProductRepository.instance.getProductsStream(),
          builder: (context, snapshot) {
            bool isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
            bool hasError = snapshot.hasError;

            List<CategoryProduct> currentProducts = [];

            if (snapshot.hasData) {
              final firestoreMatches = ProductRepository.instance.filterByCategory(
                snapshot.data!,
                widget.categoryLabel,
                categories: dbCategories,
              );

              currentProducts = firestoreMatches.map((p) {
                String imgPath = p.imageUrl;
                if (imgPath.startsWith('assets/')) {
                  imgPath = imgPath.replaceFirst('assets/', 'assests/');
                }
                return CategoryProduct(
                  name: p.name,
                  unit: p.unit.isNotEmpty ? p.unit : '1 item',
                  price: p.price,
                  originalPrice: (p.originalPrice != null && p.originalPrice! > 0) ? p.originalPrice : null,
                  rating: 4.8,
                  tag: p.isFeatured ? 'Featured' : (p.originalPrice != null && p.originalPrice! > p.price ? 'Sale' : null),
                  tagColor: (p.originalPrice != null && p.originalPrice! > p.price) ? const Color(0xFFEF4444) : const Color(0xFF3A5A2A),
                  imagePath: imgPath.isNotEmpty ? imgPath : null,
                  fallbackIcon: Icons.shopping_basket_rounded,
                );
              }).toList();
            }

            final filtered = _getFilteredProductsList(currentProducts, categoryData.filters);

            return Scaffold(
              backgroundColor: categoryData.bgColor,
              body: SafeArea(
                child: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        // ── App Bar ────────────────────────────────────────────
                        SliverAppBar(
                          backgroundColor: categoryData.bgColor,
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
                                    categoryData.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A2D1A),
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                // Top Cart Button with Dynamic Badge Count
                                ListenableBuilder(
                                  listenable: CartService.instance,
                                  builder: (context, _) {
                                    final totalCount = CartService.instance.totalItemCount;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder: (ctx, anim, _) => const CartScreen(),
                                            transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(1.0, 0.0),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                              child: child,
                                            ),
                                            transitionDuration: const Duration(milliseconds: 350),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
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
                                              Icons.shopping_cart_outlined,
                                              size: 20,
                                              color: accent,
                                            ),
                                          ),
                                          if (totalCount > 0)
                                            Positioned(
                                              top: -4,
                                              right: -4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$totalCount',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
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
                                  categoryData.filters.length,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _FilterChip(
                                      label: categoryData.filters[i],
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

                        // ── Product Grid / Loading / Error / Empty States ──────
                        if (isLoading)
                          SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(color: accent),
                            ),
                          )
                        else if (hasError)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Error loading products from Firebase',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 64, color: accent.withValues(alpha: 0.3)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No products available in this category.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4B5563),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
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
                                  final origIdx = currentProducts.indexOf(product);
                                  return _ProductCard(
                                    product: product,
                                    quantity: CartService.instance.getQuantityForProduct(product.name),
                                    accentColor: accent,
                                    onAdd: () => _addToCartProduct(product, origIdx, categoryData.title),
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),

                // ── Cart Bar at bottom ───────────────────────────────────────
                ListenableBuilder(
                  listenable: CartService.instance,
                  builder: (context, _) {
                    final count = CartService.instance.totalItemCount;
                    final total = CartService.instance.subtotal;
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      bottom: 12,
                      left: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (ctx, anim, _) => const CartScreen(),
                              transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          );
                        },
                        child: _CartBar(
                          count: count,
                          total: total,
                          accentColor: accent,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  },
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
                            ? ((product.imagePath!.startsWith('http://') || product.imagePath!.startsWith('https://'))
                                ? Image.network(
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
                                : Image.asset(
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
                                  ))
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
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
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
                                if (widget.quantity > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${widget.quantity}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
