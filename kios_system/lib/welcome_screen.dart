import 'dart:async';
import 'package:flutter/material.dart';

import 'category.dart';
import 'category_repository.dart';
import 'category_card.dart';
import 'language_button.dart';
import 'cart_button.dart';
import 'cart_database.dart';
import 'my_cart_page.dart';
import 'all_deals_page.dart';
import 'app_theme.dart';
import 'promotion_model.dart';
import 'promotion_repository.dart';

/// The main self-checkout kiosk welcome screen.
///
/// Designed for landscape 10"-12" tablets. Uses a responsive grid that
/// adapts column count and spacing to the available width/height via
/// [LayoutBuilder] + [MediaQuery].
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedLanguage = 'English';
  int _cartItemCount = 0;

  late PageController _promoPageController;
  int _currentPromoPage = 0;
  Timer? _promoAutoScrollTimer;
  int _totalPromosCount = 0;

  @override
  void initState() {
    super.initState();
    _promoPageController = PageController(viewportFraction: 0.98);
    _loadCartCount();
    _startPromoAutoScroll();
  }

  @override
  void dispose() {
    _promoAutoScrollTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    _promoAutoScrollTimer?.cancel();
    _promoAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _totalPromosCount <= 1 || !_promoPageController.hasClients) return;
      final nextPage = (_currentPromoPage + 1) % _totalPromosCount;
      _promoPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _loadCartCount() async {
    final items = await CartDatabase.instance.getItems();
    if (!mounted) return;
    setState(() => _cartItemCount = items.length);
  }

  void _onCategoryTap(CategoryItem category) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AllDealsPage(category: category)))
        .then((_) => _loadCartCount());
  }

  void _onAllDealsTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AllDealsPage()))
        .then((_) => _loadCartCount());
  }

  void _onCartTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const MyCartPage()))
        .then((_) => _loadCartCount());
  }

  void _onHelpTap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Need Help?'),
        content: const Text(
          'Please ask a store assistant nearby, or tap any category or promotion to '
          'start browsing your items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double width = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(width),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Live Firestore Promotions Banner Carousel ────────
                    _buildPromotionsCarousel(width),
                    const SizedBox(height: 16),
                    // ── Quick All Deals / Offers Strip ───────────────────
                    _buildAllDealsBanner(width),
                    const SizedBox(height: 20),
                    // ── Categories Grid ──────────────────────────────────
                    _buildCategoryGrid(width),
                    const SizedBox(height: 24),
                    CartButton(
                      itemCount: _cartItemCount,
                      onTap: _onCartTap,
                      width: width.clamp(0.0, 1400.0) * 0.34,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------
  Widget _buildHeader(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'What are you shopping today?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).withLanguageAndHelpRow(
      selectedLanguage: _selectedLanguage,
      onLanguageSelected: (lang) => setState(() => _selectedLanguage = lang),
      onHelpTap: _onHelpTap,
    );
  }

  // ---------------------------------------------------------------------
  // PROMOTIONS BANNER CAROUSEL (Live streaming from Firestore Promotions)
  // ---------------------------------------------------------------------
  Widget _buildPromotionsCarousel(double width) {
    return StreamBuilder<List<PromotionModel>>(
      stream: KioskPromotionRepository.instance.getPromotionsStream(),
      builder: (context, snapshot) {
        final promos = snapshot.data ?? PromotionModel.fallbackPromotions;
        _totalPromosCount = promos.length;

        if (promos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SizedBox(
              height: 165,
              child: PageView.builder(
                controller: _promoPageController,
                itemCount: promos.length,
                onPageChanged: (i) {
                  setState(() => _currentPromoPage = i);
                },
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  return _buildPromotionCard(promo, width);
                },
              ),
            ),
            if (promos.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  promos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPromoPage == i ? 24 : 7,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPromoPage == i
                          ? AppColors.brand
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPromotionCard(PromotionModel promo, double width) {
    // Choose banner background color theme
    Color bgGradientStart = const Color(0xFF1B8A3D);
    Color bgGradientEnd = const Color(0xFF0D5E26);

    if (promo.type.toLowerCase().contains('bogo')) {
      bgGradientStart = const Color(0xFF6B21A8);
      bgGradientEnd = const Color(0xFF4C1D95);
    } else if (promo.value >= 25) {
      bgGradientStart = const Color(0xFF9D174D);
      bgGradientEnd = const Color(0xFF831843);
    } else if (promo.scope.toLowerCase().contains('veg') ||
        promo.scope.toLowerCase().contains('fruit')) {
      bgGradientStart = const Color(0xFF1E3A1A);
      bgGradientEnd = const Color(0xFF0F260D);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _onAllDealsTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgGradientStart, bgGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: bgGradientStart.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // If Cloudinary / web image banner is provided
                if (promo.isWebImage)
                  Positioned.fill(
                    child: Image.network(
                      promo.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                // Semi-transparent gradient overlay to ensure text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: promo.isWebImage ? 0.72 : 0.15),
                          Colors.black.withValues(alpha: promo.isWebImage ? 0.40 : 0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Decorative icon blob
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    Icons.local_offer_rounded,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9A825),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    promo.discountDisplay,
                                    style: const TextStyle(
                                      color: Color(0xFF1B1B1B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (promo.couponCode.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.confirmation_number_outlined,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Code: ${promo.couponCode}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promo.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo.description.isNotEmpty
                                  ? promo.description
                                  : 'Tap to browse all active discounts & promotions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop Deal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: bgGradientStart,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 16, color: bgGradientStart),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ALL DEALS & OFFERS BANNER
  // ---------------------------------------------------------------------
  Widget _buildAllDealsBanner(double width) {
    return GestureDetector(
      onTap: _onAllDealsTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FCF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFE65100), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotions & Special Deals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Browse all promotional discounts and marked down items',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All Deals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CATEGORY GRID — dynamic grid streaming from Firestore categories table
  // ---------------------------------------------------------------------
  Widget _buildCategoryGrid(double width) {
    final int crossAxisCount = width > 900 ? 3 : 2;
    final double aspectRatio = width > 900 ? 1.55 : 1.35;

    return StreamBuilder<List<CategoryItem>>(
      stream: KioskCategoryRepository.instance.getCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }

        final categories = snapshot.data ?? kCategories;

        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No categories available.',
                style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              onTap: () => _onCategoryTap(category),
            );
          },
        );
      },
    );
  }
}

/// Small layout helper that overlays the language selector (left) and help
/// button (right) on top of the centered logo row, keeping the logo truly
/// centered regardless of language-button width.
extension on Widget {
  Widget withLanguageAndHelpRow({
    required String selectedLanguage,
    required ValueChanged<String> onLanguageSelected,
    required VoidCallback onHelpTap,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        this,
        Positioned(
          left: 0,
          child: Row(
            children: [
              LanguageButton(
                label: 'English',
                selected: selectedLanguage == 'English',
                onTap: () => onLanguageSelected('English'),
              ),
              const SizedBox(width: 8),
              LanguageButton(
                label: 'Sinhala',
                selected: selectedLanguage == 'Sinhala',
                onTap: () => onLanguageSelected('Sinhala'),
              ),
              const SizedBox(width: 8),
              LanguageButton(
                label: 'Tamil',
                selected: selectedLanguage == 'Tamil',
                onTap: () => onLanguageSelected('Tamil'),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onHelpTap,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF1B8A3D),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
