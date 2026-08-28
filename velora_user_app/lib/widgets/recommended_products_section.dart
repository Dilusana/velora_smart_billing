import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../screens/home_screen.dart' show VeloraColors;
import '../services/user_activity_service.dart';
import 'product_quantity_modal.dart';

enum RecommendationSectionType {
  personalized,
  similar,
  cartCrossSell,
  postPurchase,
  popular,
}

class RecommendedProductsSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Future<List<ProductModel>> Function() fetchProducts;
  final VoidCallback? onSeeAll;
  final RecommendationSectionType type;

  const RecommendedProductsSection({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    required this.fetchProducts,
    this.onSeeAll,
    this.type = RecommendationSectionType.personalized,
  });

  @override
  State<RecommendedProductsSection> createState() => _RecommendedProductsSectionState();
}

class _RecommendedProductsSectionState extends State<RecommendedProductsSection> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecommendedProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _load();
    }
  }

  void _load() {
    _future = widget.fetchProducts();
  }

  void _onProductTap(BuildContext context, ProductModel product) {
    // Log view activity
    UserActivityService.instance.logProductView(
      productId: product.id,
      productName: product.name,
      categoryId: product.categoryId,
      categoryName: product.category,
    );

    // Open detail / quantity modal
    ProductQuantityModal.show(
      context,
      productId: product.id,
      productName: product.name,
      category: product.category,
      unit: product.unit,
      basePrice: product.price,
      imageUrl: product.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: VeloraColors.textPrimary,
                        ),
                      ),
                      if (widget.badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VeloraColors.lime,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.badgeText!,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: VeloraColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: VeloraColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (widget.onSeeAll != null)
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: Text(
                    'See All',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VeloraColors.limeDeep,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Products Carousel / Loader ──────────────────────────────
        FutureBuilder<List<ProductModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader();
            }

            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 228,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: products.length,
                itemBuilder: (ctx, i) => _buildProductCard(ctx, products[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    String imgPath = product.imageUrl;
    if (imgPath.startsWith('assets/')) {
      imgPath = imgPath.replaceFirst('assets/', 'assests/');
    }
    final bool isNetwork = imgPath.startsWith('http://') || imgPath.startsWith('https://');

    return GestureDetector(
      onTap: () => _onProductTap(context, product),
      child: Container(
        width: 156,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: VeloraColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with Recommendation Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: imgPath.isNotEmpty
                        ? (isNetwork
                            ? Image.network(
                                imgPath,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildFallbackIcon(product),
                              )
                            : Image.asset(
                                imgPath,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildFallbackIcon(product),
                              ))
                        : _buildFallbackIcon(product),
                  ),
                ),
                if (product.originalPrice != null && product.originalPrice! > product.price)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VeloraColors.badgeRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SALE',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.unit.isNotEmpty ? product.unit : '1 unit',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: VeloraColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VeloraColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Price & Add to Cart
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs ${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: VeloraColors.textPrimary,
                        ),
                      ),
                      if (product.originalPrice != null && product.originalPrice! > product.price)
                        Text(
                          'Rs ${product.originalPrice!.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            color: VeloraColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _onProductTap(context, product),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: VeloraColors.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ProductModel product) {
    IconData icon = Icons.shopping_basket_rounded;
    Color color = const Color(0xFFFFFBEB);
    final cat = product.category.toLowerCase();
    if (cat.contains('veg') || cat.contains('fruit')) {
      icon = Icons.eco_rounded;
      color = const Color(0xFFF0FDF4);
    } else if (cat.contains('beverag')) {
      icon = Icons.local_drink_rounded;
      color = const Color(0xFFF0F5FA);
    } else if (cat.contains('chill') || cat.contains('dairy')) {
      icon = Icons.kitchen_rounded;
      color = const Color(0xFFF0F8FA);
    }
    return Container(
      color: color,
      child: Center(
        child: Icon(icon, size: 36, color: VeloraColors.limeDeep),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SizedBox(
      height: 228,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 4,
        itemBuilder: (ctx, i) => Container(
          width: 156,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VeloraColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: VeloraColors.sectionBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: VeloraColors.navy),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Finding for you...',
                        style: GoogleFonts.outfit(fontSize: 10, color: VeloraColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 60, color: VeloraColors.divider),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 110, color: VeloraColors.divider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
