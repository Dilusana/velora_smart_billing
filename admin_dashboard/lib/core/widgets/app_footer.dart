import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  late Timer _timer;
  int _minutesSinceSync = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _minutesSinceSync++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _minutesSinceSync = 0;
      });
    }
  }

  void _showModalInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: AppTextStyles.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final syncText = _minutesSinceSync == 0 
        ? 'just now' 
        : '$_minutesSinceSync min${_minutesSinceSync == 1 ? '' : 's'} ago';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.bgDarkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              Text(
                'RetailNova Enterprise Retail Management • v1.0 • Last Sync: $syncText',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isSyncing ? null : _handleSync,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSyncing) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isSyncing ? 'Syncing...' : 'Sync now',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Right side
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/help-center'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
                child: const Text('Documentation'),
              ),
              Text(
                '•',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => _showModalInfo('Privacy Policy', 'This is a mock privacy policy for RetailNova Enterprise.'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
                child: const Text('Privacy Policy'),
              ),
              Text(
                '•',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => _showModalInfo('Terms of Service', 'These are the mock terms of service for RetailNova Enterprise.'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
                child: const Text('Terms of Service'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
