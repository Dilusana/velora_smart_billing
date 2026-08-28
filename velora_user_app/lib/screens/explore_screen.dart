import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';
import 'category_screen.dart';

// ─── Category Item Model ──────────────────────────────────────────────────────

class ExploreCategory {
  final String? id;
  final String label;
  final String imagePath;
  final Color overlayColor;
  final bool isWebImage;

  const ExploreCategory({
    this.id,
    required this.label,
    required this.imagePath,
    required this.overlayColor,
    this.isWebImage = false,
  });
}

// ─── Explore Screen ───────────────────────────────────────────────────────────

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<ExploreCategory> _fallbackCategories = [
    ExploreCategory(
      label: 'Vegetables\n& Fruits',
      imagePath: 'assests/veg_fruits.png',
      overlayColor: Color(0xFF2D5A1E),
    ),
    ExploreCategory(
      label: 'Groceries',
      imagePath: 'assests/grocery.png',
      overlayColor: Color(0xFF5A4A1E),
    ),
    ExploreCategory(
      label: 'Beverages',
      imagePath: 'assests/beverages.png',
      overlayColor: Color(0xFF1E3A5A),
    ),
    ExploreCategory(
      label: 'Household',
      imagePath: 'assests/household.png',
      overlayColor: Color(0xFF4A2D5A),
    ),
    ExploreCategory(
      label: 'Chilled\nFoods',
      imagePath: 'assests/chilledfood.png',
      overlayColor: Color(0xFF1E4A5A),
    ),
    ExploreCategory(
      label: 'Frozen\nFoods',
      imagePath: 'assests/frozenfoods.jpeg',
      overlayColor: Color(0xFF1A2D5A),
    ),
  ];

  Color _getOverlayColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('veg') || lower.contains('fruit')) return const Color(0xFF2D5A1E);
    if (lower.contains('groc')) return const Color(0xFF5A4A1E);
    if (lower.contains('beverag')) return const Color(0xFF1E3A5A);
    if (lower.contains('house')) return const Color(0xFF4A2D5A);
    if (lower.contains('chill')) return const Color(0xFF1E4A5A);
    if (lower.contains('frozen')) return const Color(0xFF1A2D5A);
    return const Color(0xFF2D4A3E);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F0),
      body: SafeArea(
        child: StreamBuilder<List<CategoryModel>>(
          stream: CategoryRepository.instance.getCategoriesStream(),
          builder: (context, snapshot) {
            List<ExploreCategory> categories = _fallbackCategories;

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              categories = snapshot.data!.map((cat) {
                String imgPath = cat.imageAsset;
                if (imgPath.startsWith('assets/')) {
                  imgPath = imgPath.replaceFirst('assets/', 'assests/');
                }
                return ExploreCategory(
                  id: cat.id,
                  label: cat.title,
                  imagePath: imgPath,
                  overlayColor: _getOverlayColor(cat.title),
                  isWebImage: cat.isWebImage,
                );
              }).toList();
            }

            final filtered = _searchQuery.isEmpty
                ? categories
                : categories
                    .where((c) => c.label.toLowerCase().replaceAll('\n', ' ').contains(_searchQuery.toLowerCase()))
                    .toList();

            return CustomScrollView(
              slivers: [
                // ── App Bar with Back Button ─────────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFFF5F8F0),
                  elevation: 0,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 64,
                  title: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF3A5A2A),
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Page Title + Search Bar ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop by Category',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2D1A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search categories…',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          color: Color(0xFF9CA3AF), size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Category Grid ───────────────────────────────────────
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 60,
                                  color: const Color(0xFF3A5A2A).withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'No categories found',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: const Color(0xFF3A5A2A).withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _CategoryCard(category: filtered[i]),
                            childCount: filtered.length,
                          ),
                        ),
                      ),

                // ── Bottom padding ──────────────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final ExploreCategory category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
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
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: () {
        final label = widget.category.id ?? widget.category.label;
        final screen = CategoryScreen(categoryLabel: label);
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, _) => screen,
            transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background image ──────────────────────────────────
              widget.category.isWebImage
                  ? Image.network(
                      widget.category.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: widget.category.overlayColor.withValues(alpha: 0.3),
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.white54, size: 40),
                      ),
                    )
                  : Image.asset(
                      widget.category.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: widget.category.overlayColor.withValues(alpha: 0.3),
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.white54, size: 40),
                      ),
                    ),

              // ── Gradient overlay (bottom-heavy) ───────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      widget.category.overlayColor.withValues(alpha: 0.25),
                      widget.category.overlayColor.withValues(alpha: 0.80),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // ── Category label ────────────────────────────────────
              Positioned(
                bottom: 14,
                left: 14,
                right: 8,
                child: Text(
                  widget.category.label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Subtle top-right arrow indicator ─────────────────
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 13,
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
