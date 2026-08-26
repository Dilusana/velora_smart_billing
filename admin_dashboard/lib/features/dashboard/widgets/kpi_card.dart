import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String delta;
  final Color deltaColor;
  final Color deltaBgColor;
  final IconData icon;
  final Color accentColor;
  final String targetRoute;
  final bool isLoading;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
    required this.deltaBgColor,
    required this.icon,
    required this.accentColor,
    required this.targetRoute,
    this.isLoading = false,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isLoading) {
      return _buildSkeleton(isDark);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Use GoRouter to navigate, ignoring errors here if route isn't set up yet
          try {
            context.go(widget.targetRoute);
          } catch (e) {
            debugPrint("Navigation error: $e");
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: widget.accentColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.1 : 0.05),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.accentColor, size: 24),
                  ),
                  if (widget.delta.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.deltaBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.delta,
                        style: GoogleFonts.inter(
                          color: widget.deltaColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: GoogleFonts.inter(
                  textStyle: AppTextStyles.statValue.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title.toUpperCase(),
                style: GoogleFonts.inter(
                  textStyle: AppTextStyles.statLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    return Container(
      width: 260,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
          const Spacer(),
          Container(width: 120, height: 24, color: baseColor),
          const SizedBox(height: 8),
          Container(width: 80, height: 12, color: baseColor),
        ],
      ),
    );
  }
}
