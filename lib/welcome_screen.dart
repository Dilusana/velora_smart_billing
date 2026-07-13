import 'package:flutter/material.dart';

import 'category.dart';
import 'category_card.dart';
import 'language_button.dart';
import 'cart_button.dart';
import 'cart_database.dart';
import 'kiosk_background.dart';
import 'my_cart_page.dart';
import 'all_deals_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCartCount();
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
          'Please ask a store assistant nearby, or tap any category to '
          'start scanning your items.',
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Stack(
          children: [
            // Background pattern + waves.
            Positioned.fill(
              child: CustomPaint(
                painter: const KioskBackgroundPainter(),
              ),
            ),
            Column(
              children: [
                _buildHeader(width),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        const SizedBox(height: 22),
                        // All Deals banner removed as per request
                        const SizedBox(height: 20),
                        _buildCategoryGrid(width),
                        const SizedBox(height: 26),
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
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 14),
      child: Row(
        children: [
          // Spacer to balance the help button so the logo stays centered.
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
                          color: Color(0xFF1B1B1B),
                          letterSpacing: 0.2,
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'What are you shopping today?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: Colors.grey.shade500,
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
  // WELCOME SECTION
  // ---------------------------------------------------------------------


  // ---------------------------------------------------------------------
  // CATEGORY GRID — responsive 2 rows x 3 columns on tablets, collapsing
  // to 2 columns on narrower / portrait-ish widths.
  // ---------------------------------------------------------------------
  Widget _buildAllDealsBanner(double width) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AllDealsPage()))
            .then((_) => _loadCartCount());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B8A3D), Color(0xFF0FA861)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B8A3D).withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_offer_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'All Deals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Up to 33% off — limited time offers!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B8A3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(double width) {
    final int crossAxisCount = width > 900 ? 3 : 2;
    final double aspectRatio = width > 900 ? 1.55 : 1.35;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        final category = kCategories[index];
        return CategoryCard(
          category: category,
          onTap: () => _onCategoryTap(category),
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
