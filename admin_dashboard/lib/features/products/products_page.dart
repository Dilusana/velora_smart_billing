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
import 'duplicate_products_dialog.dart';
import 'product_providers.dart';
import 'csv_product_service.dart';

class ProductsPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const ProductsPage({super.key, this.initialCategory});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  String _sortFilter = 'Name A-Z';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _categoryFilter = widget.initialCategory!;
    }
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != null && widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        _categoryFilter = widget.initialCategory!;
      });
    }
  }

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

    // ── Build Category Filter Options ────────────────────────────────────────
    final Map<String, String> categoryFilterOptions = {'All': 'All'};

    for (final c in categories) {
      categoryFilterOptions[c.name] = c.name;
    }

    for (final p in products) {
      if (p.category.isNotEmpty) {
        final existingKey = categoryFilterOptions.keys.firstWhere(
          (k) => k.toLowerCase().trim() == p.category.toLowerCase().trim(),
          orElse: () => '',
        );
        if (existingKey.isEmpty) {
          final formatted = p.category.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
          categoryFilterOptions[p.category] = formatted;
        }
      }
    }

    // Determine current dropdown value
    String selectedCategoryValue = 'All';
    if (_categoryFilter != 'All') {
      final match = categoryFilterOptions.keys.firstWhere(
        (k) => k.toLowerCase().trim() == _categoryFilter.toLowerCase().trim() ||
            k.toLowerCase().replaceAll(' ', '').replaceAll('&', 'and') == _categoryFilter.toLowerCase().replaceAll(' ', '').replaceAll('&', 'and'),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        selectedCategoryValue = match;
      } else {
        categoryFilterOptions[_categoryFilter] = _categoryFilter;
        selectedCategoryValue = _categoryFilter;
      }
    }

    // ── Filter Products ──────────────────────────────────────────────────────
    var filteredProducts = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesCategory = true;
      if (_categoryFilter != 'All') {
        final filterClean = _categoryFilter.toLowerCase().trim();
        final pCatClean = p.category.toLowerCase().trim();

        final catObj = categories.cast<CategoryModel?>().firstWhere(
          (c) => c?.name.toLowerCase().trim() == filterClean || c?.id.toLowerCase().trim() == filterClean,
          orElse: () => null,
        );

        matchesCategory = (pCatClean == filterClean) ||
            (catObj != null && (pCatClean == catObj.id.toLowerCase().trim() || pCatClean == catObj.name.toLowerCase().trim())) ||
            pCatClean.replaceAll(' ', '').replaceAll('&', 'and') == filterClean.replaceAll(' ', '').replaceAll('&', 'and') ||
            pCatClean.contains(filterClean) || filterClean.contains(pCatClean);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final bool isExpired = p.expiryDate != null && DateTime(p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day).isBefore(today);
      final bool isExpiringSoon = p.expiryDate != null &&
          !isExpired &&
          DateTime(p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day).difference(today).inDays <= 30;

      final matchesStatus = _statusFilter == 'All' || 
          (_statusFilter == 'Active' && (p.status == 'active')) ||
          (_statusFilter == 'Inactive' && (p.status != 'active')) ||
          (_statusFilter == 'Out of Stock' && p.stock <= 0) ||
          (_statusFilter == 'Expiring Soon' && isExpiringSoon) ||
          (_statusFilter == 'Expired' && isExpired);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Products', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredProducts.length} ${filteredProducts.length == 1 ? 'product' : 'products'} available',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                      label: const Text('Clean Duplicates'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusAmber,
                        side: const BorderSide(color: AppColors.statusAmber),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => DuplicateProductsDialog(allProducts: products),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Sample CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onPressed: () => CsvProductService.downloadSampleCsv(context),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(FontAwesomeIcons.fileCsv, size: 16),
                      label: const Text('Export CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onPressed: () => CsvProductService.exportProductsToCsv(context, products),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Import CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () => CsvProductService.importProductsFromCsv(context, ref),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

            // ── Search & Filter Controls ─────────────────────────────────────
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
                        isExpanded: true,
                        value: selectedCategoryValue,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Category',
                        ),
                        items: categoryFilterOptions.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _categoryFilter = val ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _statusFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Status',
                        ),
                        items: ['All', 'Active', 'Inactive', 'Out of Stock', 'Expiring Soon', 'Expired']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _statusFilter = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _sortFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          labelText: 'Sort By',
                        ),
                        items: ['Name A-Z', 'Price Low-High', 'Stock Low-High']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _sortFilter = val!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Active Filter Chip indicator
            if (_categoryFilter != 'All' || _statusFilter != 'All' || _searchQuery.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_categoryFilter != 'All')
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text('Category: $_categoryFilter'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _categoryFilter = 'All'),
                    ),
                  if (_statusFilter != 'All')
                    Chip(
                      avatar: const Icon(Icons.filter_list, size: 16),
                      label: Text('Status: $_statusFilter'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _statusFilter = 'All'),
                    ),
                  if (_searchQuery.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.search, size: 16),
                      label: Text('Search: "$_searchQuery"'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _searchQuery = ''),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Products Data Table ──────────────────────────────────────────
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
                            if (_categoryFilter != 'All') ...[
                              const SizedBox(height: 8),
                              Text('No products in category "$_categoryFilter"', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Show All Categories'),
                                onPressed: () => setState(() => _categoryFilter = 'All'),
                              ),
                            ],
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
                          DataColumn2(label: Text('Expiry'), size: ColumnSize.M),
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
                          final bool isNetwork = p.imageUrl.startsWith('http://') || p.imageUrl.startsWith('https://');

                          final String expiryText = p.expiryDate != null
                              ? DateFormat('dd MMM yyyy').format(p.expiryDate!)
                              : '—';
                          final bool isExpired = p.expiryDate != null && p.expiryDate!.isBefore(DateTime.now());

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
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: hasImage
                                              ? (isNetwork
                                                  ? Image.network(
                                                      p.imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                                                    )
                                                  : Image.asset(
                                                      p.imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20, color: Colors.grey),
                                                    ))
                                              : const Icon(Icons.image, color: Colors.grey),
                                        ),
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
                              DataCell(
                                Text(
                                  expiryText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: p.expiryDate != null ? FontWeight.w600 : FontWeight.normal,
                                    color: isExpired ? AppColors.statusRed : null,
                                  ),
                                ),
                              ),
                              DataCell(statusBadge),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.visibility, size: 20), onPressed: () => context.go('/products/${p.id}'), tooltip: 'View', color: AppColors.textMuted),
                                  IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {
                                    showDialog(context: context, builder: (context) => ProductFormDialog(product: p));
                                  }, tooltip: 'Edit', color: AppColors.textMuted),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Product'),
                                          content: Text('Are you sure you want to delete "${p.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.statusRed,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(firestoreProductsProvider.notifier).delete(p.id);
                                      }
                                    },
                                    tooltip: 'Delete',
                                    color: AppColors.statusRed,
                                  ),
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

  Widget _buildBadge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
