import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E8),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App Bar ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            _IconBtn(
                              icon: Icons.menu_rounded,
                              onTap: () {},
                            ),
                            const Spacer(),
                            Text(
                              'My Profile',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3A5A2A),
                              ),
                            ),
                            const Spacer(),
                            _IconBtn(
                              icon: Icons.settings_outlined,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Profile Header ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFCEE847),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assests/dairy_banner.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFEEF5C8),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 52,
                                        color: Color(0xFF3A5A2A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Edit button
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF3A5A2A),
                                    border: Border.all(
                                      color: const Color(0xFFF5F2E8),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: Color(0xFFCEE847),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Name
                          Text(
                            'Sarah Jenkins',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Gold Member Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFDE68A), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 14,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'GOLD MEMBER',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB45309),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Stats Row ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5C8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              _StatTile(value: '24', label: 'ORDERS'),
                              _StatDivider(),
                              _StatTile(value: '1,240', label: 'POINTS'),
                              _StatDivider(),
                              _StatTile(value: '12', label: 'SAVED'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Personal Information ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _MenuSection(
                          label: 'PERSONAL INFORMATION',
                          items: [
                            _MenuItem(
                              icon: Icons.person_outline_rounded,
                              title: 'Edit Profile',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.location_on_outlined,
                              title: 'Shipping Addresses',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.credit_card_outlined,
                              title: 'Payment Methods',
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // ── Activity ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _MenuSection(
                          label: 'ACTIVITY',
                          items: [
                            _MenuItem(
                              icon: Icons.receipt_long_outlined,
                              title: 'Order History',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.rate_review_outlined,
                              title: 'My Reviews',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.checklist_rounded,
                              title: 'Shopping Lists',
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // ── Support & Legal ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _MenuSection(
                          label: 'SUPPORT & LEGAL',
                          items: [
                            _MenuItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Help Center',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              trailingIcon: Icons.open_in_new_rounded,
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.gavel_rounded,
                              title: 'Terms of Service',
                              trailingIcon: Icons.open_in_new_rounded,
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // ── Account ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _MenuSection(
                          label: 'ACCOUNT',
                          items: [
                            _MenuItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notification Settings',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.translate_rounded,
                              title: 'Language',
                              trailingLabel: 'English',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              isDestructive: true,
                              showChevron: false,
                              onTap: () => _showLogoutDialog(context),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom padding for nav bar
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),

            // ── Bottom Navigation Bar ────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: false,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            label: 'Categories',
            isActive: false,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Cart',
            isActive: false,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            isActive: false,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFDC2626), size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                'Log Out?',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .popUntil((r) => r.isFirst),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFDC2626).withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

// ─── Icon Button ──────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3A5A2A), size: 20),
      ),
    );
  }
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF3A5A2A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Divider ─────────────────────────────────────────────────────────────

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFF3A5A2A).withValues(alpha: 0.18),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;

  const _MenuSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.7,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final IconData? trailingIcon;
  final String? trailingLabel;
  final bool isDestructive;
  final bool showChevron;
  final bool isLast;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailingIcon,
    this.trailingLabel,
    this.isDestructive = false,
    this.showChevron = true,
    this.isLast = false,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final iconColor = widget.isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF3A5A2A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF9F9F6) : Colors.transparent,
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  if (widget.trailingLabel != null) ...[
                    Text(
                      widget.trailingLabel!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.trailingIcon != null)
                    Icon(widget.trailingIcon!, size: 16,
                        color: const Color(0xFF9CA3AF))
                  else if (widget.showChevron)
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
            if (!widget.isLast)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(
                  height: 1,
                  color: const Color(0xFFF3F4F6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 56 : 44,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3A5A2A) : Colors.transparent,
              borderRadius: BorderRadius.circular(isActive ? 14 : 0),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFF3A5A2A)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
