import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'my_cart_page.dart';
import 'product_model.dart';
import 'product_repository.dart';
import 'deal_product_detail_page.dart';

class BeverageListingPage extends StatefulWidget {
  const BeverageListingPage({super.key});

  @override
  State<BeverageListingPage> createState() => _BeverageListingPageState();
}

class _BeverageListingPageState extends State<BeverageListingPage> {
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

  Future<void> _addToCart(ProductModel product) async {
    final item = CartItem(
      productId: product.id,
      category: 'Beverages',
      title: product.name,
      description: product.description,
      price: product.price,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    if (!mounted) return;
    _refreshCartCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
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

  List<ProductModel> _filterBeverages(List<ProductModel> rawProducts) {
    var beverages = rawProducts.where((p) {
      return KioskProductRepository.instance.productMatchesCategory(p, 'Beverages');
    }).toList();

    if (_searchQuery.trim().isEmpty) return beverages;

    final q = _searchQuery.trim().toLowerCase();
    return beverages.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brand, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 20),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beverages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryText)),
              SizedBox(height: 6),
              Text('Premium self-checkout selection', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
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
              color: AppColors.secondaryBackground,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openCart,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.shopping_cart_rounded, color: AppColors.brand, size: 28),
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
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Browse top-selling beverages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: KioskProductRepository.instance.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.brand),
                      SizedBox(height: 12),
                      Text('Loading beverages...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading beverages: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final allProducts = snapshot.data ?? [];
              final products = _filterBeverages(allProducts);

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_drink_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No beverage products found',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    const color = AppColors.info;
    final bool hasWebImage = product.isWebImage;
    final bool hasAssetImage = product.isAssetImage;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DealProductDetailPage(product: product),
          ),
        ).then((_) => _refreshCartCount());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFECF2ED)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.08),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_drink_rounded, color: color, size: 24),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: hasWebImage
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: 108,
                            height: 108,
                            errorBuilder: (_, __, ___) => const Icon(Icons.local_drink_rounded, size: 56, color: color),
                          )
                        : hasAssetImage
                            ? Image.asset(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: 108,
                                height: 108,
                                errorBuilder: (_, __, ___) => const Icon(Icons.local_drink_rounded, size: 56, color: color),
                              )
                            : const Icon(Icons.local_drink_rounded, size: 56, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(product.description.isNotEmpty ? product.description : 'Refreshing beverage', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Rs.${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B8A3D))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.stock > 10 ? const Color(0xFFE9F7ED) : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      product.stock > 10 ? 'In stock' : 'Low stock: ${product.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: product.stock > 10 ? AppColors.brand : AppColors.cta,
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
                    backgroundColor: AppColors.brand,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
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
              side: const BorderSide(color: AppColors.brand),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand)),
          ),
        ),
      ],
    );
  }
}
