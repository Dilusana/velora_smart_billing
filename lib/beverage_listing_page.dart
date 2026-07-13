import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'my_cart_page.dart';

class BeverageListingPage extends StatefulWidget {
  const BeverageListingPage({super.key});

  @override
  State<BeverageListingPage> createState() => _BeverageListingPageState();
}

class BeverageProduct {
  final String title;
  final String subtitle;
  final double price;
  final int stock;
  final Color color;
  final IconData icon;

  const BeverageProduct({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.stock,
    required this.color,
    required this.icon,
  });
}

class _BeverageListingPageState extends State<BeverageListingPage> {
  final List<BeverageProduct> _products = const [
    BeverageProduct(
      title: 'Coca Cola 1L',
      subtitle: 'Classic sparkling cola',
      price: 1.95,
      stock: 12,
      color: Color(0xFFE53935),
      icon: Icons.local_drink_rounded,
    ),
    BeverageProduct(
      title: 'Sprite 1L',
      subtitle: 'Lemon-lime refreshment',
      price: 1.85,
      stock: 15,
      color: Color(0xFF43A047),
      icon: Icons.emoji_food_beverage_rounded,
    ),
    BeverageProduct(
      title: 'Pepsi 1L',
      subtitle: 'Bold cola flavor',
      price: 1.88,
      stock: 10,
      color: Color(0xFF1E88E5),
      icon: Icons.local_cafe_rounded,
    ),
    BeverageProduct(
      title: 'Elephant House Necto',
      subtitle: 'Fruit juice drink',
      price: 2.10,
      stock: 8,
      color: Color(0xFFFDD835),
      icon: Icons.local_bar_rounded,
    ),
    BeverageProduct(
      title: 'Highland Water',
      subtitle: 'Pure mineral water',
      price: 0.95,
      stock: 25,
      color: Color(0xFF4FC3F7),
      icon: Icons.water_drop_rounded,
    ),
    BeverageProduct(
      title: 'Red Bull',
      subtitle: 'Energy drink boost',
      price: 2.55,
      stock: 14,
      color: Color(0xFFEF5350),
      icon: Icons.bolt_rounded,
    ),
    BeverageProduct(
      title: 'Monster Energy',
      subtitle: 'Zero sugar energy',
      price: 2.45,
      stock: 9,
      color: Color(0xFF2E7D32),
      icon: Icons.power_outlined,
    ),
  ];

  String _searchQuery = '';
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart(BeverageProduct product) async {
    final item = CartItem(
      category: 'Beverages',
      title: product.title,
      description: product.subtitle,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    if (!mounted) return;
    _refreshCartCount();
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

  List<BeverageProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((product) => product.title.toLowerCase().contains(_searchQuery.toLowerCase()) || product.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 24),
              Expanded(child: _buildProductGrid(context)),
              const SizedBox(height: 20),
              _buildBottomRow(context),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B8A3D), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Beverages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
              SizedBox(height: 6),
              Text('Premium self-checkout selection', style: TextStyle(fontSize: 14, color: Color(0xFF5E6A76))),
            ],
          ),
        ),
        const SizedBox(width: 20),
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
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                hintText: 'Search beverages',
                hintStyle: TextStyle(color: Color(0xFF94A58B)),
                border: InputBorder.none,
                suffixIcon: Icon(Icons.search_rounded, color: Color(0xFF1B8A3D)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Stack(
          children: [
            Material(
              color: const Color(0xFFF3FCF5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openCart,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.shopping_cart_rounded, color: Color(0xFF1B8A3D), size: 28),
                ),
              ),
            ),
            if (_cartCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A3D),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_cartCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final products = _filteredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Browse top-selling beverages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B1B1B))),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 22,
              crossAxisSpacing: 22,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BeverageProduct product) {
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: product.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(product.icon, color: product.color, size: 24),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: product.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(product.icon, size: 56, color: product.color.withOpacity(0.92)),
              ),
            ),
            const SizedBox(height: 18),
            Text(product.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B1B1B))),
            const SizedBox(height: 6),
            Text(product.subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B8A3D))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: product.stock > 10 ? const Color(0xFFE9F7ED) : const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    product.stock > 10 ? 'In stock' : 'Low stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: product.stock > 10 ? const Color(0xFF1B8A3D) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A3D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _openCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8A3D),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('View Cart ($_cartCount)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: OutlinedButton(
            onPressed: _continueShopping,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B8A3D)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B8A3D))),
          ),
        ),
      ],
    );
  }
}
