import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';
import 'deal_product_detail_page.dart';
import 'my_cart_page.dart';
import 'app_theme.dart';
import 'product_model.dart';
import 'product_repository.dart';
import 'promotion_model.dart';
import 'promotion_repository.dart';

enum DealSort { newest, priceAsc, priceDesc }

class AllDealsPage extends StatefulWidget {
  final CategoryItem? category;

  const AllDealsPage({super.key, this.category});

  @override
  State<AllDealsPage> createState() => _AllDealsPageState();
}

class _AllDealsPageState extends State<AllDealsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  DealSort _sort = DealSort.newest;
  int _cartCount = 0;

  static const Color _green = Color(0xFF1B8A3D);

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshCart() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartCount = items.length);
  }

  Future<void> _addToCart(ProductModel p) async {
    final item = CartItem(
      productId: p.id,
      category: p.category.isNotEmpty ? p.category : 'General',
      title: p.name,
      description: p.description,
      price: p.price,
      quantity: 1,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    await _refreshCart();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.name} added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> rawList) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = rawList;

    // Category filter
    if (widget.category != null) {
      list = list.where((p) {
        return KioskProductRepository.instance.productMatchesCategory(
          p,
          widget.category!.title,
          categoryId: widget.category!.id,
        );
      }).toList();
    }

    // Search query filter
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    // Sorting
    switch (_sort) {
      case DealSort.newest:
        list.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            return b.createdAt!.compareTo(a.createdAt!);
          }
          return 0;
        });
        break;
      case DealSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case DealSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<PromotionModel>>(
        stream: KioskPromotionRepository.instance.getPromotionsStream(),
        builder: (context, promoSnapshot) {
          final activePromotions =
              promoSnapshot.data ?? PromotionModel.fallbackPromotions;

          return StreamBuilder<List<ProductModel>>(
            stream: KioskProductRepository.instance.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return _buildScaffoldLayout(
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _green),
                        SizedBox(height: 16),
                        Text('Loading products from Firestore...'),
                      ],
                    ),
                  ),
                  count: 0,
                  activePromos: activePromotions,
                );
              }

              if (snapshot.hasError) {
                return _buildScaffoldLayout(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load products: ${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  count: 0,
                  activePromos: activePromotions,
                );
              }

              final allProducts = snapshot.data ?? [];
              final filteredProducts = _filterAndSortProducts(allProducts);

              return _buildScaffoldLayout(
                count: filteredProducts.length,
                activePromos: activePromotions,
                child: filteredProducts.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (_, i) {
                          final product = filteredProducts[i];
                          final matchingPromo = KioskPromotionRepository.instance
                              .getPromotionForProduct(
                                  product, activePromotions);

                          return _DealCard(
                            product: product,
                            promotion: matchingPromo,
                            onAddToCart: () => _addToCart(product),
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => DealProductDetailPage(
                                      product: product,
                                      promotion: matchingPromo,
                                    ),
                                  ),
                                )
                                .then((_) => _refreshCart()),
                          );
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScaffoldLayout({
    required Widget child,
    required int count,
    required List<PromotionModel> activePromos,
  }) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        if (activePromos.isNotEmpty) _buildActivePromotionsRibbon(activePromos),
        _buildCountSortBar(count),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildHeader() {
    final title = widget.category?.title ?? 'All Deals & Promotions';

    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyCartPage()))
                .then((_) => _refreshCart()),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 24),
                  ),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9A825),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green, width: 1.5),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            hintText: widget.category == null
                ? 'Search products, deals, discounts...'
                : 'Search ${widget.category!.title.toLowerCase()}',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildActivePromotionsRibbon(List<PromotionModel> promos) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded,
                size: 16, color: Color(0xFF1B8A3D)),
            const SizedBox(width: 8),
            const Text(
              'Active Offers:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B8A3D),
              ),
            ),
            const SizedBox(width: 8),
            ...promos.map((p) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B8A3D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9A825),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.discountDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCountSortBar(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const TextSpan(
                  text: ' products found',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const Spacer(),
          _SortDropdown(
            value: _sort,
            onChanged: (v) => setState(() => _sort = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final DealSort value;
  final ValueChanged<DealSort> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  static const _labels = {
    DealSort.newest: 'Newest',
    DealSort.priceAsc: 'Price ↑',
    DealSort.priceDesc: 'Price ↓',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1B8A3D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DealSort>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Color(0xFF1B8A3D)),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B8A3D)),
          items: DealSort.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(_labels[s]!),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final ProductModel product;
  final PromotionModel? promotion;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _DealCard({
    required this.product,
    this.promotion,
    required this.onAddToCart,
    required this.onTap,
  });

  static const Color _green = Color(0xFF1B8A3D);

  @override
  Widget build(BuildContext context) {
    final bool hasWebImage = product.isWebImage;
    final bool hasAssetImage = product.isAssetImage;
    final bool hasPromo = promotion != null;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: hasWebImage
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 42,
                                  color: _green),
                            )
                          : hasAssetImage
                              ? Image.asset(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.shopping_bag_rounded,
                                      size: 42,
                                      color: _green),
                                )
                              : const Icon(Icons.shopping_bag_rounded,
                                  size: 42, color: _green),
                    ),
                  ),
                  if (hasPromo)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promotion!.discountDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                        ),
                        if (hasPromo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFFB74D), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer,
                                    size: 11, color: Color(0xFFE65100)),
                                const SizedBox(width: 3),
                                Text(
                                  promotion!.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Rs.${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: product.stock > 10
                                ? const Color(0xFFE9F7ED)
                                : const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.stock > 10
                                ? 'In stock'
                                : 'Low stock: ${product.stock}',
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
                    const SizedBox(height: 3),
                    Text(
                      product.unit.isNotEmpty
                          ? 'Unit: ${product.unit}'
                          : 'Category: ${product.category}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onAddToCart,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded,
                          color: _green, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
