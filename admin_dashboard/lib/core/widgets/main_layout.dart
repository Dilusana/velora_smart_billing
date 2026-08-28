import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'app_sidebar.dart';
import 'app_header.dart';
import 'app_footer.dart';

// Provide global access to sidebar expanded state
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically collapse sidebar on narrow screens
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;
    
    // Using a microtask to avoid changing state during build if needed,
    // but typically it's handled via LayoutBuilder or similar.
    // For simplicity, we just watch the state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMobile && ref.read(sidebarExpandedProvider)) {
        ref.read(sidebarExpandedProvider.notifier).state = false;
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppHeader(),
                
                // Dynamic Page Content
                Expanded(
                  child: ClipRRect(
                    // ensure content doesn't bleed behind corners if styled
                    child: child,
                  ),
                ),
                
                // Bottom Footer
                const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
