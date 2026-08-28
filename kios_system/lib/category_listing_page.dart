import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';
import 'my_cart_page.dart';
import 'app_theme.dart';
import 'product_model.dart';
import 'product_repository.dart';
import 'deal_product_detail_page.dart';
import 'promotion_model.dart';
import 'promotion_repository.dart';

class CategoryListingPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryListingPage({super.key, required this.category});

  @override
  State<CategoryListingPage> createState() => _CategoryListingPageState();
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

  Future<void> _refreshCartCount() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart(ProductModel product) async {
    final item = CartItem(
      productId: product.id,
      category: widget.category.title,
      title: product.name,
      description: product.description,
      price: product.price,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    if (!mounted) return;
    await _refreshCartCount();
    if (!mounted) return;
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

  List<ProductModel> _filterProducts(List<ProductModel> rawProducts) {
    final query = _searchController.text.trim().toLowerCase();
    
    // First filter by category
    var categoryProducts = rawProducts.where((p) {
      return KioskProductRepository.instance.productMatchesCategory(
        p,
        widget.category.title,
        categoryId: widget.category.id,
      );
    }).toList();

    // If query is empty, return category filtered products
    if (query.isEmpty) {
      return categoryProducts;
    }

    return categoryProducts.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1400 ? 4 : width > 1100 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: StreamBuilder<List<PromotionModel>>(
                        stream: KioskPromotionRepository.instance.getPromotionsStream(),
                        builder: (context, promoSnapshot) {
                          final activePromos = promoSnapshot.data ?? PromotionModel.fallbackPromotions;

                          return StreamBuilder<List<ProductModel>>(
                            stream: KioskProductRepository.instance.getProductsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: AppColors.brand),
                                      SizedBox(height: 12),
                                      Text('Loading products...'),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error loading products: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                );
                              }

                              final allProducts = snapshot.data ?? [];
                              final products = _filterProducts(allProducts);

                              if (products.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No products found in ${widget.category.title}',
                                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: products.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 22,
                                  mainAxisSpacing: 22,
                                  childAspectRatio: 0.72,
                                ),
                                itemBuilder: (context, index) {
                                  final p = products[index];
                                  final promo = KioskPromotionRepository.instance
                                      .getPromotionForProduct(p, activePromos);
                                  return _buildProductCard(p, promo);
                                },
                              );
                            },
                          );
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
                  color: AppColors.brand, size: 20),
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
                      color: AppColors.primaryText)),
              const SizedBox(height: 6),
              Text(widget.category.description,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.secondaryText)),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 2,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                hintText:
                    'Search ${widget.category.title.toLowerCase()}',
                hintStyle: const TextStyle(color: AppColors.disabledText),
                border: InputBorder.none,
                suffixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.brand),
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
                      color: AppColors.brand, size: 28),
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
                        color: Colors.black.withValues(alpha: 0.16),
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

  Widget _buildProductCard(ProductModel product, [PromotionModel? promotion]) {
    const accent = AppColors.brand;
    final bool hasWebImage = product.isWebImage;
    final bool hasAssetImage = product.isAssetImage;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DealProductDetailPage(
              product: product,
              promotion: promotion,
            ),
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
              color: const Color(0xFF1B8A3D).withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (promotion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        promotion.discountDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: accent, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: hasWebImage
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, size: 48, color: accent),
                          )
                        : hasAssetImage
                            ? Image.asset(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, size: 48, color: accent),
                              )
                            : const Icon(Icons.shopping_bag_rounded, size: 48, color: accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1B1B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.description.isNotEmpty ? product.description : product.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Rs.${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B8A3D),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: product.stock > 10
                          ? const Color(0xFFE9F7ED)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.stock > 10 ? 'In stock' : 'Low stock: ${product.stock}',
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
                height: 46,
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
}