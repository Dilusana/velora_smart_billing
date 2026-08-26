import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/product_quantity_modal.dart';

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
  String _searchQuery = '';
  String _selectedSort = 'Recommended';
  String _selectedTagFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  late final PageController _bannerController;
  late Timer _bannerTimer;
  late AnimationController _navAnimController;



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
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer.cancel();
    _navAnimController.dispose();
    super.dispose();
  }

  void _addToCart({ProductItem? item, ProductModel? modelItem}) {
    final String title = modelItem?.name ?? item?.name ?? 'Fresh Item';
    final String category = modelItem?.category ?? 'Grocery';
    final String desc = modelItem?.unit ?? item?.unit ?? '1 unit';
    final double price = modelItem?.price ?? item?.price ?? 1.0;
    final String img = modelItem?.imageUrl ?? item?.imagePath ?? '';
    final String pId = modelItem?.id ?? 'prod_${title.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    ProductQuantityModal.show(
      context,
      productId: pId,
      productName: title,
      category: category,
      unit: desc,
      basePrice: price,
      imageUrl: img,
      fallbackIcon: item?.icon ?? Icons.shopping_basket_rounded,
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
                      StreamBuilder<List<ProductModel>>(
                        stream: ProductRepository.instance.getProductsStream(),
                        builder: (context, snapshot) {
                          final products = snapshot.hasData ? snapshot.data! : <ProductModel>[];
                          final filtered = _getFilteredFirestoreProducts(products);
                          return _buildFirestoreProductHorizontalList(filtered);
                        },
                      ),
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
            // Avatar (Tap to direct to ProfileScreen)
            GestureDetector(
              onTap: () {
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
                );
              },
              child: Container(
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
          StreamBuilder<User?>(
            stream: FirebaseAuthService.instance.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data ?? FirebaseAuthService.instance.currentUser;
              String firstName = 'Shopper';
              if (user != null) {
                if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
                  firstName = user.displayName!.trim().split(' ').first;
                } else if (user.email != null && user.email!.contains('@')) {
                  final part = user.email!.split('@').first;
                  if (part.isNotEmpty) {
                    firstName = part[0].toUpperCase() + part.substring(1);
                  }
                }
              }
              return Text(
                'Hello, $firstName! 👋',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: VeloraColors.textPrimary,
                  height: 1.2,
                ),
              );
            },
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
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search fresh produce, dairy…',
                hintStyle: GoogleFonts.outfit(
                  color: VeloraColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: VeloraColors.textMuted, size: 20),
                suffixIcon: GestureDetector(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_selectedSort != 'Recommended' || _selectedTagFilter != 'All')
                          ? VeloraColors.navy
                          : VeloraColors.lime,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: (_selectedSort != 'Recommended' || _selectedTagFilter != 'All')
                          ? Colors.white
                          : VeloraColors.navy,
                      size: 18,
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
          if (_selectedSort != 'Recommended' || _selectedTagFilter != 'All' || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_selectedTagFilter != 'All')
                  _buildFilterChip('Tag: $_selectedTagFilter', () => setState(() => _selectedTagFilter = 'All')),
                if (_selectedSort != 'Recommended')
                  _buildFilterChip('Sort: $_selectedSort', () => setState(() => _selectedSort = 'Recommended')),
                if (_searchQuery.isNotEmpty)
                  _buildFilterChip('Query: "$_searchQuery"', () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onClear) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VeloraColors.sectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeloraColors.limeDeep.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VeloraColors.navy,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 14, color: VeloraColors.navy),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: VeloraColors.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VeloraColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Filter Products',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: VeloraColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedSort = 'Recommended';
                            _selectedTagFilter = 'All';
                          });
                          setState(() {
                            _selectedSort = 'Recommended';
                            _selectedTagFilter = 'All';
                          });
                        },
                        child: Text(
                          'Reset All',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: VeloraColors.badgeRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort By',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: VeloraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Recommended', 'Price: Low to High', 'Price: High to Low'].map((sortOption) {
                      final isSel = _selectedSort == sortOption;
                      return ChoiceChip(
                        label: Text(sortOption),
                        selected: isSel,
                        selectedColor: VeloraColors.navy,
                        backgroundColor: VeloraColors.bg,
                        labelStyle: GoogleFonts.outfit(
                          color: isSel ? Colors.white : VeloraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setModalState(() => _selectedSort = sortOption);
                          setState(() => _selectedSort = sortOption);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Filter by Tag',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: VeloraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Sale', 'Best Seller'].map((tagOption) {
                      final isSel = _selectedTagFilter == tagOption;
                      return ChoiceChip(
                        label: Text(tagOption),
                        selected: isSel,
                        selectedColor: VeloraColors.limeDeep,
                        backgroundColor: VeloraColors.bg,
                        labelStyle: GoogleFonts.outfit(
                          color: isSel ? Colors.white : VeloraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setModalState(() => _selectedTagFilter = tagOption);
                          setState(() => _selectedTagFilter = tagOption);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VeloraColors.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: VeloraColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (ctx, anim, _) => const ExploreScreen(),
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
                child: Text(
                  'View All',
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
        const SizedBox(height: 14),
        SizedBox(
          height: 126,
          child: StreamBuilder<List<CategoryModel>>(
            stream: CategoryRepository.instance.getCategoriesStream(),
            builder: (context, snapshot) {
              final dbCategories = snapshot.hasData && snapshot.data!.isNotEmpty
                  ? snapshot.data!
                  : CategoryRepository.fallbackCategories;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dbCategories.length,
                itemBuilder: (ctx, i) {
                  final cat = dbCategories[i];
                  final isSelected = _selectedCategory == i;

                  String imgPath = cat.imageAsset;
                  if (imgPath.startsWith('assets/')) {
                    imgPath = imgPath.replaceFirst('assets/', 'assests/');
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = i);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (ctx, anim, _) => CategoryScreen(
                            categoryLabel: cat.title,
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
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 104,
                      decoration: BoxDecoration(
                        color: isSelected ? VeloraColors.navy : VeloraColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? VeloraColors.lime : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? VeloraColors.navy.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : VeloraColors.sectionBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: imgPath.isNotEmpty
                                  ? cat.isWebImage
                                      ? Image.network(
                                          imgPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildCategoryIconFallback(cat.title, isSelected),
                                        )
                                      : Image.asset(
                                          imgPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildCategoryIconFallback(cat.title, isSelected),
                                        )
                                  : _buildCategoryIconFallback(cat.title, isSelected),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.title,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : VeloraColors.textPrimary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIconFallback(String title, bool isSelected) {
    IconData icon = Icons.shopping_basket_rounded;
    Color color = const Color(0xFFF59E0B);
    final lower = title.toLowerCase();
    if (lower.contains('veg') || lower.contains('fruit')) {
      icon = Icons.eco_rounded;
      color = const Color(0xFF22C55E);
    } else if (lower.contains('house')) {
      icon = Icons.home_rounded;
      color = const Color(0xFF8B5CF6);
    } else if (lower.contains('frozen')) {
      icon = Icons.ac_unit_rounded;
      color = const Color(0xFF3B82F6);
    } else if (lower.contains('chill')) {
      icon = Icons.kitchen_rounded;
      color = const Color(0xFF06B6D4);
    } else if (lower.contains('beverag')) {
      icon = Icons.local_drink_rounded;
      color = const Color(0xFFEF4444);
    }

    return Container(
      color: isSelected ? VeloraColors.lime : color.withValues(alpha: 0.12),
      child: Icon(icon, color: isSelected ? VeloraColors.navy : color, size: 20),
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

  List<ProductModel> _getFilteredFirestoreProducts(List<ProductModel> originalList) {
    List<ProductModel> list = List.from(originalList);

    if (_searchQuery.isNotEmpty) {
      list = ProductRepository.instance.searchProducts(list, _searchQuery);
    }

    if (_selectedTagFilter == 'Sale') {
      list = list.where((p) => p.originalPrice != null && p.originalPrice! > p.price).toList();
    } else if (_selectedTagFilter == 'Best Seller') {
      list = list.where((p) => p.isFeatured).toList();
    }

    if (_selectedSort == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  Widget _buildFirestoreProductHorizontalList(List<ProductModel> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No products found matching filters',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: VeloraColors.textMuted,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildFirestoreProductCard(items[i]),
      ),
    );
  }

  Widget _buildFirestoreProductCard(ProductModel item) {
    String imgPath = item.imageUrl;
    if (imgPath.startsWith('assets/')) {
      imgPath = imgPath.replaceFirst('assets/', 'assests/');
    }
    final bool isNetworkImage = imgPath.startsWith('http://') || imgPath.startsWith('https://');

    return Container(
      width: 154,
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
              child: imgPath.isNotEmpty
                  ? (isNetworkImage
                      ? Image.network(
                          imgPath,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildProductFallbackBg(item),
                        )
                      : Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildProductFallbackBg(item),
                        ))
                  : _buildProductFallbackBg(item),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.unit.isNotEmpty ? item.unit : '1 unit',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs ${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: VeloraColors.textPrimary,
                      ),
                    ),
                    if (item.originalPrice != null && item.originalPrice! > item.price)
                      Text(
                        'Rs ${item.originalPrice!.toStringAsFixed(2)}',
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
                  onTap: () => _addToCart(modelItem: item),
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
    );
  }

  Widget _buildProductFallbackBg(ProductModel item) {
    IconData icon = Icons.shopping_basket_rounded;
    Color color = const Color(0xFFFFFBEB);
    final catLower = item.category.toLowerCase();
    if (catLower.contains('veg') || catLower.contains('fruit')) {
      icon = Icons.eco_rounded;
      color = const Color(0xFFF0FDF4);
    } else if (catLower.contains('house')) {
      icon = Icons.home_rounded;
      color = const Color(0xFFF8F0FA);
    } else if (catLower.contains('beverag')) {
      icon = Icons.local_drink_rounded;
      color = const Color(0xFFF0F5FA);
    } else if (catLower.contains('chill')) {
      icon = Icons.kitchen_rounded;
      color = const Color(0xFFF0F8FA);
    }
    return Container(
      color: color,
      child: Center(
        child: Icon(icon, size: 44, color: VeloraColors.limeDeep),
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
                  if (isCart)
                    ListenableBuilder(
                      listenable: CartService.instance,
                      builder: (context, _) {
                        final count = CartService.instance.totalItemCount;
                        if (count <= 0) return const SizedBox.shrink();
                        return Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: const BoxDecoration(
                              color: VeloraColors.badgeRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
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
