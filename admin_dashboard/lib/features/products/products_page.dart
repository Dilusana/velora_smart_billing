import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../categories/category_provider.dart';
import 'product_form_dialog.dart';
import 'product_providers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  String _sortFilter = 'Name A-Z';
  List<String> _selectedIds = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(firestoreProductsProvider);
    final categoriesAsync = ref.watch(categoriesFirestoreProvider);
    final categories = categoriesAsync.value ?? [];

    // Handle loading and error states
    if (productsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (productsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load products', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(productsAsync.error.toString(), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(firestoreProductsProvider),
            ),
          ],
        ),
      );
    }
    final products = productsAsync.value ?? [];

    var filteredProducts = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == 'All' || p.category == _categoryFilter;
      final matchesStatus = _statusFilter == 'All' || 
          (_statusFilter == 'Active' && (p.status == 'active')) ||
          (_statusFilter == 'Inactive' && (p.status != 'active')) ||
          (_statusFilter == 'Out of Stock' && p.stock <= 0);
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    if (_sortFilter == 'Name A-Z') {
      filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortFilter == 'Price Low-High') {
      filteredProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortFilter == 'Stock Low-High') {
      filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
    }

    return Material(
      color: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Products', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(FontAwesomeIcons.fileCsv, size: 16),
                      label: const Text('Export CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ProductFormDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search products by name or SKU...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoryFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Category',
                        ),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All')),
                          ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) => setState(() => _categoryFilter = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Status',
                        ),
                        items: ['All', 'Active', 'Inactive', 'Out of Stock'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _statusFilter = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Sort By',
                        ),
                        items: ['Name A-Z', 'Price Low-High', 'Stock Low-High'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _sortFilter = val!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('${_selectedIds.length} products selected', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('Change Category')),
                    TextButton(onPressed: () {}, child: const Text('Export Selected')),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
                      onPressed: () {
                        // ref.read(productsProvider.notifier).deleteMultiple(_selectedIds);
                        setState(() => _selectedIds.clear());
                      },
                      child: const Text('Delete Selected'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Card(
                elevation: 0,
                color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.boxOpen, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No products found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 16,
                        minWidth: 900,
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? AppColors.bgDark : AppColors.bgPrimary,
                        ),
                        columns: const [
                          DataColumn2(label: Text('Product'), size: ColumnSize.L),
                          DataColumn2(label: Text('Category'), size: ColumnSize.M),
                          DataColumn2(label: Text('Price'), size: ColumnSize.S),
                          DataColumn2(label: Text('Cost'), size: ColumnSize.S),
                          DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                        ],
                        rows: filteredProducts.map((p) {
                          final c = categories.firstWhere(
                            (cat) => cat.id == p.category || cat.name.toLowerCase() == p.category.toLowerCase(),
                            orElse: () => CategoryModel(
                              id: '',
                              name: p.category.isNotEmpty ? p.category : 'Uncategorized',
                              description: '',
                              imageUrl: '',
                              productCount: 0,
                              revenueShare: 0,
                            ),
                          );

                          Widget statusBadge;
                          if (p.stock <= 0) {
                            statusBadge = _buildBadge('Out of Stock', AppColors.statusRed, AppColors.statusRedBg);
                          } else if (p.status == 'active') {
                            statusBadge = _buildBadge('Active', AppColors.statusGreen, AppColors.statusGreenBg);
                          } else {
                            statusBadge = _buildBadge('Inactive', AppColors.statusGray, AppColors.statusGrayBg);
                          }

                          final hasImage = p.imageUrl.isNotEmpty;

                          return DataRow2(
                            cells: [
                              DataCell(
                                InkWell(
                                  onTap: () => context.go('/products/${p.id}'),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey[200],
                                          image: hasImage
                                              ? DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover)
                                              : null,
                                        ),
                                        child: hasImage ? null : const Icon(Icons.image, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(p.sku, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(c.name)),
                              DataCell(Text(NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2).format(p.price))),
                              DataCell(Text(NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2).format(p.cost))),
                              DataCell(Text('${p.stock} ${p.unit}')),
                              DataCell(statusBadge),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.visibility, size: 20), onPressed: () => context.go('/products/${p.id}'), tooltip: 'View', color: AppColors.textMuted),
                                  IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {
                                    showDialog(context: context, builder: (context) => ProductFormDialog(product: p));
                                  }, tooltip: 'Edit', color: AppColors.textMuted),
                                  IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () async {
                                    await ref.read(firestoreProductsProvider.notifier).delete(p.id);
                                  }, tooltip: 'Delete', color: AppColors.statusRed),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

