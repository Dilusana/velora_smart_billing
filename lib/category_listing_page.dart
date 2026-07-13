import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';
import 'my_cart_page.dart';

class CategoryListingPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryListingPage({super.key, required this.category});

  @override
  State<CategoryListingPage> createState() => _CategoryListingPageState();
}

class CategoryProduct {
  final String title;
  final String subtitle;
  final double price;
  final int stock;
  final IconData icon;
  final Color accent;

  const CategoryProduct({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.stock,
    required this.icon,
    required this.accent,
  });
}

class _CategoryListingPageState extends State<CategoryListingPage> {
  final TextEditingController _searchController = TextEditingController();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCartCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryProduct> get _products {
    return _productsForCategory(widget.category.title);
  }

  Future<void> _refreshCartCount() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart(CategoryProduct product) async {
    final item = CartItem(
      category: widget.category.title,
      title: product.title,
      description: product.subtitle,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    if (!mounted) return;
    await _refreshCartCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1100),
      ),
    );
  }

  void _openCart() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const MyCartPage()))
        .then((_) => _refreshCartCount());
  }

  void _continueShopping() {
    Navigator.of(context).pop();
  }

  List<CategoryProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1400 ? 4 : width > 1100 ? 3 : 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 26),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Browse top-selling items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: products.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 22,
                          mainAxisSpacing: 22,
                          childAspectRatio: 0.72, // Fixed from 0.88
                        ),
                        itemBuilder: (context, index) {
                          return _buildProductCard(products[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Material(
          color: const Color(0xFFF3FCF5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1B8A3D), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.category.title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B1B1B))),
              const SizedBox(height: 6),
              Text(widget.category.description,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF5E6A76))),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 2,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EFE6)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                hintText:
                    'Search ${widget.category.title.toLowerCase()}',
                hintStyle: const TextStyle(color: Color(0xFF94A58B)),
                border: InputBorder.none,
                suffixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF1B8A3D)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 22),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: const Color(0xFFF3FCF5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openCart,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.shopping_cart_rounded,
                      color: Color(0xFF1B8A3D), size: 28),
                ),
              ),
            ),
            if (_cartCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A3D),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text('$_cartCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductCard(CategoryProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECF2ED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8A3D).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14), // Reduced from 18
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 40, // Reduced from 44
                height: 40, // Reduced from 44
                decoration: BoxDecoration(
                  color: product.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(product.icon, color: product.accent, size: 22),
              ),
            ),
            const SizedBox(height: 10), // Reduced from 18
            Container(
              height: 90, // Reduced from 120
              decoration: BoxDecoration(
                color: product.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(product.icon,
                    size: 48, // Reduced from 56
                    color: product.accent.withOpacity(0.92)),
              ),
            ),
            const SizedBox(height: 10), // Reduced from 18
            Text(product.title,
                style: const TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B))),
            const SizedBox(height: 4), // Reduced from 6
            Text(product.subtitle,
                style: const TextStyle(
                    fontSize: 12, // Reduced from 13
                    color: Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10), // Reduced from 14
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B8A3D)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: product.stock > 10
                        ? const Color(0xFFE9F7ED)
                        : const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.stock > 10 ? 'In stock' : 'Low stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: product.stock > 10
                          ? const Color(0xFF1B8A3D)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46, // Reduced from 52
              child: ElevatedButton(
                onPressed: () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A3D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _openCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8A3D),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('View Cart ($_cartCount)',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: OutlinedButton(
            onPressed: _continueShopping,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B8A3D)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Continue Shopping',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B8A3D))),
          ),
        ),
      ],
    );
  }

  List<CategoryProduct> _productsForCategory(String category) {
    switch (category) {
      case 'Vegetables & Fruits':
        return const [
          CategoryProduct(
            title: 'Bananas',
            subtitle: 'Ripe bunch of bananas',
            price: 1.20,
            stock: 18,
            icon: Icons.eco_rounded,
            accent: Color(0xFF63A35C),
          ),
          CategoryProduct(
            title: 'Red Apples',
            subtitle: 'Sweet crisp apples',
            price: 1.80,
            stock: 12,
            icon: Icons.apple_rounded,
            accent: Color(0xFFDB4343),
          ),
          CategoryProduct(
            title: 'Fresh Spinach',
            subtitle: 'Green leaf bundle',
            price: 3.40,
            stock: 9,
            icon: Icons.grass,
            accent: Color(0xFF4CAF50),
          ),
          CategoryProduct(
            title: 'Roma Tomatoes',
            subtitle: 'Juicy tomato pack',
            price: 2.50,
            stock: 15,
            icon: Icons.spa_rounded,
            accent: Color(0xFFEF5350),
          ),
        ];
      case 'Grocery':
        return const [
          CategoryProduct(
            title: 'Whole Wheat Bread',
            subtitle: 'Fresh bakery loaf',
            price: 2.90,
            stock: 16,
            icon: Icons.bakery_dining_rounded,
            accent: Color(0xFF8D6E63),
          ),
          CategoryProduct(
            title: 'Rice 5kg',
            subtitle: 'Premium long grain',
            price: 12.50,
            stock: 11,
            icon: Icons.rice_bowl_rounded,
            accent: Color(0xFF6D4C41),
          ),
          CategoryProduct(
            title: 'Salt & Spices',
            subtitle: 'Savory seasoning set',
            price: 4.10,
            stock: 14,
            icon: Icons.spa_rounded,
            accent: Color(0xFFF9A825),
          ),
          CategoryProduct(
            title: 'Cooking Oil',
            subtitle: 'Healthy vegetable oil',
            price: 5.30,
            stock: 10,
            icon: Icons.local_fire_department_rounded,
            accent: Color(0xFFFDD835),
          ),
        ];
      case 'Household':
        return const [
          CategoryProduct(
            title: 'Dish Soap',
            subtitle: 'Gentle citrus cleaner',
            price: 2.40,
            stock: 20,
            icon: Icons.cleaning_services_rounded,
            accent: Color(0xFF4FC3F7),
          ),
          CategoryProduct(
            title: 'Laundry Detergent',
            subtitle: 'Fresh wash powder',
            price: 9.50,
            stock: 13,
            icon: Icons.local_laundry_service_rounded,
            accent: Color(0xFF1976D2),
          ),
          CategoryProduct(
            title: 'Floor Cleaner',
            subtitle: 'Sparkling surface care',
            price: 3.90,
            stock: 8,
            icon: Icons.bubble_chart_rounded,
            accent: Color(0xFF43A047),
          ),
          CategoryProduct(
            title: 'Paper Towels',
            subtitle: 'Soft absorbent rolls',
            price: 4.75,
            stock: 17,
            icon: Icons.cleaning_services_rounded,
            accent: Color(0xFF8E24AA),
          ),
        ];
      case 'Chilled Foods':
        return const [
          CategoryProduct(
            title: 'Greek Yogurt',
            subtitle: 'Creamy protein snack',
            price: 3.20,
            stock: 15,
            icon: Icons.icecream_rounded,
            accent: Color(0xFF5E35B1),
          ),
          CategoryProduct(
            title: 'Cheddar Cheese',
            subtitle: 'Sharp dairy slices',
            price: 4.90,
            stock: 12,
            icon: Icons.local_pizza_rounded,
            accent: Color(0xFFD32F2F),
          ),
          CategoryProduct(
            title: 'Fresh Cream',
            subtitle: 'Rich cooking cream',
            price: 3.60,
            stock: 10,
            icon: Icons.local_cafe_rounded,
            accent: Color(0xFF42A5F5),
          ),
          CategoryProduct(
            title: 'Ready Meal Bowl',
            subtitle: 'Hearty chilled ready-to-eat',
            price: 6.50,
            stock: 9,
            icon: Icons.dinner_dining_rounded,
            accent: Color(0xFFFB8C00),
          ),
        ];
      case 'Frozen Foods':
        return const [
          CategoryProduct(
            title: 'Frozen Peas',
            subtitle: 'Quick veggie side',
            price: 2.70,
            stock: 18,
            icon: Icons.grass_rounded,
            accent: Color(0xFF43A047),
          ),
          CategoryProduct(
            title: 'Ice Cream Tub',
            subtitle: 'Decadent dessert pint',
            price: 5.20,
            stock: 11,
            icon: Icons.icecream_rounded,
            accent: Color(0xFF7B1FA2),
          ),
          CategoryProduct(
            title: 'Vegetable Mix',
            subtitle: 'Frozen stir-fry blend',
            price: 3.30,
            stock: 14,
            icon: Icons.spa_rounded,
            accent: Color(0xFF66BB6A),
          ),
          CategoryProduct(
            title: 'Frozen Pizza',
            subtitle: 'Crispy oven-ready pie',
            price: 7.80,
            stock: 8,
            icon: Icons.local_pizza_rounded,
            accent: Color(0xFFE53935),
          ),
        ];
      default:
        return const [
          CategoryProduct(
            title: 'Featured Item',
            subtitle: 'Premium product from this category',
            price: 4.99,
            stock: 12,
            icon: Icons.shopping_bag_rounded,
            accent: Color(0xFF1B8A3D),
          ),
        ];
    }
  }
}