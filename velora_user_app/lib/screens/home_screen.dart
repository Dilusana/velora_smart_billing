import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'explore_screen.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class VeloraColors {
  static const lime = Color(0xFFCEE847);
  static const limeDeep = Color(0xFF8DC63F);
  static const limeLight = Color(0xFFF4FAD4);
  static const navy = Color(0xFF1A2D5A);
  static const navyLight = Color(0xFF2E4482);
  static const bg = Color(0xFFF9FAF5);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);
  static const badgeRed = Color(0xFFEF4444);
  static const sectionBg = Color(0xFFF0F4E8);
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final String? imagePath;
  CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    this.imagePath,
  });
}

class ProductItem {
  final String name;
  final String unit;
  final double price;
  final double? originalPrice;
  final Color cardColor;
  final IconData icon;
  final bool isFeatured;
  final String? imagePath;
  ProductItem({
    required this.name,
    required this.unit,
    required this.price,
    this.originalPrice,
    required this.cardColor,
    required this.icon,
    this.isFeatured = false,
    this.imagePath,
  });
}

class BannerData {
  final String title;
  final String subtitle;
  final String badge;
  final Color bgColor;
  final Color textColor;
  final IconData icon;
  final String? imagePath;
  BannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.bgColor,
    required this.textColor,
    required this.icon,
    this.imagePath,
  });
}

// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedNav = 0;
  int _selectedCategory = 0;
  int _bannerPage = 0;
  int _cartCount = 0;

  late final PageController _bannerController;
  late Timer _bannerTimer;
  late AnimationController _navAnimController;

  final List<CategoryItem> _categories = [
    CategoryItem(
      label: 'Veg & Fruits',
      icon: Icons.eco_rounded,
      color: const Color(0xFF22C55E),
      imagePath: 'assests/veg_fruits.png',
    ),
    CategoryItem(
      label: 'Grocery',
      icon: Icons.shopping_basket_rounded,
      color: const Color(0xFFF59E0B),
      imagePath: 'assests/grocery.png',
    ),
    CategoryItem(
      label: 'Household',
      icon: Icons.home_rounded,
      color: const Color(0xFF8B5CF6),
      imagePath: 'assests/household.png',
    ),
    CategoryItem(
      label: 'Frozen',
      icon: Icons.ac_unit_rounded,
      color: const Color(0xFF3B82F6),
      imagePath: 'assests/frozenfoods.jpeg',
    ),
    CategoryItem(
      label: 'Chilled',
      icon: Icons.kitchen_rounded,
      color: const Color(0xFF06B6D4),
      imagePath: 'assests/chilledfood.png',
    ),
    CategoryItem(
      label: 'Beverages',
      icon: Icons.local_drink_rounded,
      color: const Color(0xFFEF4444),
      imagePath: 'assests/beverages.png',
    ),
  ];

  final List<BannerData> _banners = [
    BannerData(
      title: '20% off\nOrganic\nGala Apples',
      subtitle: 'Fresh from local farms',
      badge: 'LIMITED OFFER',
      bgColor: const Color(0xFF2D4A1E),
      textColor: Colors.white,
      icon: Icons.apple_rounded,
      imagePath: 'assests/apples_banner.jpg',
    ),
    BannerData(
      title: 'Fresh\nVegetables\nDaily',
      subtitle: 'Harvested every morning',
      badge: 'FARM TO TABLE',
      bgColor: const Color(0xFF1A3A5C),
      textColor: Colors.white,
      icon: Icons.eco_rounded,
      imagePath: 'assests/vegetables_banner.jpg',
    ),
    BannerData(
      title: 'Buy 2 Get\n1 Free\nDairy',
      subtitle: 'On selected dairy products',
      badge: 'TODAY ONLY',
      bgColor: const Color(0xFF4C1D95),
      textColor: Colors.white,
      icon: Icons.icecream_rounded,
      imagePath: 'assests/dairy_banner.jpg',
    ),
  ];

  final List<ProductItem> _recommended = [
    ProductItem(
      name: 'Organic Whole Milk',
      unit: '1 Litre',
      price: 4.50,
      cardColor: const Color(0xFFFFFBEB),
      icon: Icons.icecream_rounded,
      imagePath: 'assests/milk_product.jpg',
    ),
    ProductItem(
      name: 'Premium Bananas',
      unit: 'Per kg',
      price: 2.20,
      cardColor: const Color(0xFFF0FDF4),
      icon: Icons.apple_rounded,
      imagePath: 'assests/bananas_product.jpg',
    ),
    ProductItem(
      name: 'Farm Eggs',
      unit: 'Dozen',
      price: 5.99,
      cardColor: const Color(0xFFFFF7ED),
      icon: Icons.egg_rounded,
      imagePath: 'assests/eggs_product.jpg',
    ),
    ProductItem(
      name: 'Baby Spinach',
      unit: '200g bag',
      price: 3.25,
      cardColor: const Color(0xFFF0FDF4),
      icon: Icons.eco_rounded,
      imagePath: 'assests/spinach_product.jpg',
    ),
  ];

  final List<ProductItem> _bestSellers = [
    ProductItem(
      name: 'Artisan Sourdough',
      unit: 'Per loaf',
      price: 6.00,
      cardColor: const Color(0xFFFFFBEB),
      icon: Icons.breakfast_dining_rounded,
      imagePath: 'assests/sourdough_product.jpg',
    ),
    ProductItem(
      name: 'Wildflower Honey',
      unit: '500ml jar',
      price: 8.50,
      originalPrice: 10.99,
      cardColor: const Color(0xFFFFF7ED),
      icon: Icons.local_drink_rounded,
      imagePath: 'assests/honey_product.jpg',
    ),
    ProductItem(
      name: 'Greek Yogurt',
      unit: '400g pot',
      price: 3.80,
      cardColor: const Color(0xFFF0F9FF),
      icon: Icons.icecream_rounded,
      imagePath: 'assests/yogurt_product.jpg',
    ),
    ProductItem(
      name: 'Cherry Tomatoes',
      unit: '500g punnet',
      price: 2.75,
      cardColor: const Color(0xFFFFF1F2),
      icon: Icons.eco_rounded,
      imagePath: 'assests/tomatoes_product.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer.cancel();
    _navAnimController.dispose();
    super.dispose();
  }

  void _addToCart() {
    setState(() => _cartCount++);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: VeloraColors.lime, size: 18),
            const SizedBox(width: 10),
            Text('Added to cart!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: VeloraColors.navy,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloraColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildCategories(),
                      const SizedBox(height: 24),
                      _buildBannerCarousel(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Recommended for You', 'View All'),
                      const SizedBox(height: 14),
                      _buildProductHorizontalList(_recommended),
                      const SizedBox(height: 28),
                      _buildSpecialOffer(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Best Sellers', 'See All'),
                      const SizedBox(height: 14),
                      _buildProductHorizontalList(_bestSellers),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: VeloraColors.bg,
      elevation: 0,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Logo area
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VeloraColors.lime,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: VeloraColors.navy, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Velora',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: VeloraColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // Notification button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VeloraColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded, color: VeloraColors.navy, size: 20),
            ),
            const SizedBox(width: 10),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VeloraColors.lime, VeloraColors.limeDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: VeloraColors.navy, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Shopper! 👋',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: VeloraColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fresh picks for a fresh day.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: VeloraColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: VeloraColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search fresh produce, dairy…',
                hintStyle: GoogleFonts.outfit(
                  color: VeloraColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: VeloraColors.textMuted, size: 20),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VeloraColors.lime,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: VeloraColors.navy, size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Categories ──────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Categories',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: VeloraColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VeloraColors.limeDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == i;
              // Map home-screen labels → allCategoryData keys
              const categoryKeys = [
                'Vegetables\n& Fruits',
                'Groceries',
                'Household',
                'Frozen\nFoods',
                'Chilled\nFoods',
                'Beverages',
              ];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = i);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (ctx, anim, _) => CategoryScreen(
                        categoryLabel: categoryKeys[i],
                      ),
                      transitionsBuilder: (ctx, anim, _, child) =>
                          SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                      transitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected ? VeloraColors.navy : VeloraColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? VeloraColors.navy.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image thumbnail or icon fallback
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: cat.imagePath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      cat.imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: isSelected
                                            ? VeloraColors.lime
                                            : cat.color.withValues(alpha: 0.12),
                                        child: Icon(cat.icon,
                                            color: isSelected
                                                ? VeloraColors.navy
                                                : cat.color,
                                            size: 20),
                                      ),
                                    ),
                                    // Tint overlay when selected
                                    if (isSelected)
                                      Container(
                                        color: VeloraColors.lime.withValues(alpha: 0.35),
                                      ),
                                  ],
                                )
                              : Container(
                                  color: isSelected
                                      ? VeloraColors.lime
                                      : cat.color.withValues(alpha: 0.12),
                                  child: Icon(cat.icon,
                                      color: isSelected
                                          ? VeloraColors.navy
                                          : cat.color,
                                      size: 20),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : VeloraColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

      ],
    );
  }

  // ─── Banner Carousel ─────────────────────────────────────────────────────

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (ctx, i) => _buildBannerCard(_banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerPage == i ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _bannerPage == i ? VeloraColors.limeDeep : VeloraColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(BannerData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: data.bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.bgColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Product image on the right side
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 145,
              child: data.imagePath != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Image.asset(
                        data.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          child: Icon(data.icon, color: VeloraColors.lime, size: 46),
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(data.icon, color: VeloraColors.lime, size: 46),
                    ),
            ),
            // Dark overlay on image side for readability
            if (data.imagePath != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 145,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        data.bgColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            // Text content — use Positioned so it is NOT stretched by StackFit.expand
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 130,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: VeloraColors.lime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.badge,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: VeloraColors.navy,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        data.title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: data.textColor,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: VeloraColors.lime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Shop Now',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: VeloraColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VeloraColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Text(
              action,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VeloraColors.limeDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Product Horizontal List ──────────────────────────────────────────────

  Widget _buildProductHorizontalList(List<ProductItem> items) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildProductCard(items[i]),
      ),
    );
  }

  Widget _buildProductCard(ProductItem item) {
    return Container(
      width: 148,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: VeloraColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: item.imagePath != null
                  ? Image.asset(
                      item.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: item.cardColor,
                        child: Center(
                          child: Icon(item.icon, size: 48, color: VeloraColors.limeDeep),
                        ),
                      ),
                    )
                  : Container(
                      color: item.cardColor,
                      child: Center(
                        child: Icon(item.icon, size: 48, color: VeloraColors.limeDeep),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.unit,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: VeloraColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: VeloraColors.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 10),
            child: Row(
              children: [
                Text(
                  'Rs ${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: VeloraColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _addToCart,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: VeloraColors.navy,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Special Offer ────────────────────────────────────────────────────────

  Widget _buildSpecialOffer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Offers',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VeloraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: VeloraColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image area
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assests/cheese_special.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2D1B0E), Color(0xFF4A2C0A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _OfferIcon(icon: Icons.breakfast_dining_rounded, color: const Color(0xFFF59E0B)),
                                  const SizedBox(width: 14),
                                  _OfferIcon(icon: Icons.local_drink_rounded, color: const Color(0xFF8B5CF6)),
                                  const SizedBox(width: 14),
                                  _OfferIcon(icon: Icons.eco_rounded, color: const Color(0xFF22C55E)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay for badge legibility
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: VeloraColors.lime,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LIMITED TIME',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: VeloraColors.navy,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Product info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artisan Cheese Selection',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: VeloraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Curated box from local farms. Perfect for your next gathering.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: VeloraColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Rs 18.00',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: VeloraColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rs 24.00',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: VeloraColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: VeloraColors.limeLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '25% OFF',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: VeloraColors.limeDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                          label: Text(
                            'Add to Cart',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VeloraColors.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.grid_view_rounded, 'label': 'Explore'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Cart'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: VeloraColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: VeloraColors.navy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = _selectedNav == i;
          final isCart = i == 2;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedNav = i);
              if (i == 1) {
                // Navigate to Explore
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim, _) => const ExploreScreen(),
                    transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ).then((_) => setState(() => _selectedNav = 0));
              } else if (i == 2) {
                // Navigate to Cart
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
                ).then((_) => setState(() => _selectedNav = 0));
              } else if (i == 3) {
                // Navigate to Orders
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim, _) => const OrdersScreen(),
                    transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ).then((_) => setState(() => _selectedNav = 0));
              } else if (i == 4) {
                // Navigate to Profile
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim, _) => const ProfileScreen(),
                    transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ).then((_) => setState(() => _selectedNav = 0));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? VeloraColors.lime : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isActive ? VeloraColors.navy : Colors.white.withValues(alpha: 0.55),
                        size: 22,
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          items[i]['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: VeloraColors.navy,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isCart && _cartCount > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: VeloraColors.badgeRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartCount',
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
            ),
          );
        }),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _OfferIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _OfferIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
