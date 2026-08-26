import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../categories/category_provider.dart';
import 'product_form_dialog.dart';
import 'product_providers.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class ProductDetailPage extends ConsumerWidget {
  final String id;
  const ProductDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(firestoreProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (productsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final products = productsAsync.value ?? [];
    final product = products.cast<ProductModel?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Not Found')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final categoriesAsync = ref.watch(categoriesFirestoreProvider);
    final categories = categoriesAsync.value ?? [];
    final category = categories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == product.category || c?.name.toLowerCase() == product.category.toLowerCase(),
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/products'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRed,
                    side: const BorderSide(color: AppColors.statusRed),
                  ),
                  onPressed: () => _confirmDelete(context, ref, product),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProductFormDialog(product: product),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Product summary card ─────────────────────────────────────────
            Card(
              elevation: 0,
              color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isDark ? AppColors.bgDarkBorder : AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        image: product.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(product.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: product.imageUrl.isEmpty
                          ? const Icon(Icons.image,
                              size: 56, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  category?.name ?? (product.category.isNotEmpty ? product.category : 'Uncategorized'),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('SKU: ${product.sku}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 16)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildStat('Price',
                                  _fmt(product.price)),
                              const SizedBox(width: 48),
                              _buildStat('Cost',
                                  _fmt(product.cost)),
                              const SizedBox(width: 48),
                              _buildStat(
                                'Stock',
                                '${product.stock} ${product.unit}',
                                color: product.stock <= 0
                                    ? AppColors.statusRed
                                    : AppColors.statusGreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Overview ─────────────────────────────────────────────────────
            Expanded(
              child: _OverviewTab(
                product: product,
                categoryName: category?.name ?? (product.category.isNotEmpty ? product.category : 'Uncategorized'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2).format(v);

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final router = GoRouter.of(context);
              await ref
                  .read(firestoreProductsProvider.notifier)
                  .delete(product.id);
              nav.pop();
              router.go('/products');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final ProductModel product;
  final String categoryName;
  final bool isDark;
  const _OverviewTab({
    required this.product,
    required this.categoryName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description.isNotEmpty
                ? product.description
                : 'No description provided.'),
            const SizedBox(height: 32),
            Text('Details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _detailRow('Status',
                        product.status == 'active' ? 'Active' : 'Inactive')),
                Expanded(child: _detailRow('Unit', product.unit)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _detailRow('SKU', product.sku)),
                Expanded(
                    child: _detailRow(
                        'Category', categoryName)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _detailRow('Selling Price',
                        NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2)
                            .format(product.price))),
                Expanded(
                    child: _detailRow('Cost Price',
                        NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2)
                            .format(product.cost))),
              ],
            ),
            const SizedBox(height: 8),
            _detailRow('Profit Margin',
                '${((product.price - product.cost) / product.price * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

