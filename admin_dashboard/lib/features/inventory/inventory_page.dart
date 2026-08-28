import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../products/product_providers.dart';
import '../products/duplicate_products_dialog.dart';
import '../products/csv_product_service.dart';
import 'inventory_providers.dart';

class InventoryPage extends ConsumerStatefulWidget {
  final String? initialFilter;
  const InventoryPage({Key? key, this.initialFilter}) : super(key: key);

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialFilter == 'in_stock') initialIndex = 1;
    if (widget.initialFilter == 'low_stock') initialIndex = 2;
    if (widget.initialFilter == 'out_of_stock') initialIndex = 3;
    if (widget.initialFilter == 'expiring_soon') initialIndex = 4;
    if (widget.initialFilter == 'expired') initialIndex = 5;

    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUpdateExpiryDialog(
      BuildContext context, ProductModel product, DateTime? currentExpiry) async {
    final dateFmt = DateFormat('dd MMM yyyy');
    DateTime? selectedDate = currentExpiry;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.event_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Adjust Expiry Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('SKU: ${product.sku}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select Expiry Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      child: Text(
                        selectedDate != null
                            ? dateFmt.format(selectedDate!)
                            : 'No expiry date set',
                        style: TextStyle(
                          color: selectedDate != null ? null : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                        label: const Text('Clear Expiry Date',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = null;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(product.id)
                          .update({
                        'expiryDate': selectedDate != null
                            ? Timestamp.fromDate(selectedDate!)
                            : FieldValue.delete(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      ref.invalidate(firestoreProductsProvider);
                      if (context.mounted) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          title: const Text('Expiry Date Updated'),
                          description: Text(selectedDate != null
                              ? '${product.name} expiry set to ${dateFmt.format(selectedDate!)}'
                              : '${product.name} expiry removed'),
                          autoCloseDuration: const Duration(seconds: 3),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          title: const Text('Error Updating Expiry Date'),
                          description: Text(e.toString()),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryAsync = ref.watch(inventoryWithExpiryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: inventoryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.statusRed),
                const SizedBox(height: 12),
                Text('Failed to load inventory',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(e.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          data: (items) => _buildContent(context, items, isDark),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<ProductWithExpiry> items, bool isDark) {
    final allCount = items.length;
    final inStockCount = items.where((i) => i.product.stock > 10).length;
    final lowStockCount =
        items.where((i) => i.product.stock > 0 && i.product.stock <= 10).length;
    final outOfStockCount = items.where((i) => i.product.stock <= 0).length;
    final expiringSoonCount =
        items.where((i) => i.expiryStatus == 'Expiring Soon').length;
    final expiredCount =
        items.where((i) => i.expiryStatus == 'Expired').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Management',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click on a product to view full details & history',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => DuplicateProductsDialog(
                        allProducts: items.map((i) => i.product).toList(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                  label: const Text('Clean Duplicates'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusAmber,
                    side: const BorderSide(color: AppColors.statusAmber),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => CsvProductService.downloadSampleCsv(context),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Sample CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => CsvProductService.exportProductsToCsv(
                    context,
                    items.map((i) => i.product).toList(),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => CsvProductService.importProductsFromCsv(context, ref),
                  icon: const Icon(FontAwesomeIcons.fileImport, size: 16),
                  label: const Text('Import CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Tabs + Search ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(child: Text('All ($allCount)')),
                  Tab(child: Text('In Stock ($inStockCount)')),
                  Tab(child: Row(children: [
                    Text('Low Stock ($lowStockCount)'),
                    if (lowStockCount > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                    ],
                  ])),
                  Tab(child: Row(children: [
                    Text('Out of Stock ($outOfStockCount)'),
                    if (outOfStockCount > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.error, color: Colors.red, size: 16),
                    ],
                  ])),
                  Tab(child: Row(children: [
                    Text('Expiring Soon ($expiringSoonCount)'),
                    if (expiringSoonCount > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_filled, color: Colors.amber, size: 16),
                    ],
                  ])),
                  Tab(child: Row(children: [
                    Text('Expired ($expiredCount)'),
                    if (expiredCount > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.cancel, color: Colors.red, size: 16),
                    ],
                  ])),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Table ──────────────────────────────────────────────────────────
        Expanded(
          child: Card(
            elevation: 0,
            color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: isDark ? AppColors.bgDarkBorder : AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildTable(items, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<ProductWithExpiry> items, bool isDark) {
    final q = _searchQuery.toLowerCase();
    final filtered = items.where((i) {
      // Tab filter
      final stock = i.product.stock;
      if (_tabController.index == 1 && stock <= 10) return false;
      if (_tabController.index == 2 && (stock == 0 || stock > 10)) return false;
      if (_tabController.index == 3 && stock > 0) return false;
      if (_tabController.index == 4 && i.expiryStatus != 'Expiring Soon') return false;
      if (_tabController.index == 5 && i.expiryStatus != 'Expired') return false;

      // Search filter: name OR sku
      if (q.isNotEmpty) {
        final matchName = i.product.name.toLowerCase().contains(q);
        final matchSku = i.product.sku.toLowerCase().contains(q);
        if (!matchName && !matchSku) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.boxesStacked,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No inventory items found'
                  : 'No results for "$_searchQuery"',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final currFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    return DataTable2(
      dataRowHeight: 64,
      headingRowHeight: 48,
      headingRowColor: WidgetStateProperty.all(
        isDark ? AppColors.bgDarkSurface : AppColors.bgPrimary,
      ),
      columnSpacing: 16,
      columns: const [
        DataColumn2(label: Text('Product Name'), size: ColumnSize.L),
        DataColumn2(label: Text('SKU'), size: ColumnSize.S),
        DataColumn2(label: Text('Stock'), size: ColumnSize.S),
        DataColumn2(label: Text('Expiry'), size: ColumnSize.M),
        DataColumn2(label: Text('Cost Price'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Inv. Value'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Sell Price'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text('Actions'), size: ColumnSize.M),
      ],
      rows: filtered.map((item) {
        final p = item.product;
        final stock = p.stock;
        final bool isLowStock = stock > 0 && stock <= 10;
        final bool isOutOfStock = stock <= 0;

        Widget stockBadge;
        if (isOutOfStock) {
          stockBadge = _badge('Out of Stock', AppColors.statusRed, AppColors.statusRedBg);
        } else if (isLowStock) {
          stockBadge = _badge('Low Stock', AppColors.statusAmber, AppColors.statusAmberBg);
        } else {
          stockBadge = _badge('In Stock', AppColors.statusGreen, AppColors.statusGreenBg);
        }

        Widget expiryBadge;
        switch (item.expiryStatus) {
          case 'Expired':
            expiryBadge = _badge('Expired', AppColors.statusRed, AppColors.statusRedBg);
            break;
          case 'Expiring Soon':
            expiryBadge = _badge('Expiring Soon', AppColors.statusAmber, AppColors.statusAmberBg);
            break;
          case 'N/A':
            expiryBadge = _badge('N/A', AppColors.statusGray, AppColors.statusGrayBg);
            break;
          default:
            expiryBadge = _badge('Normal', AppColors.statusGreen, AppColors.statusGreenBg);
        }

        final expiryDateVal = p.expiryDate ?? item.earliestExpiry;
        final expiryText = expiryDateVal != null
            ? dateFmt.format(expiryDateVal)
            : '—';

        final double invValue = p.cost * stock;

        return DataRow2(
          onTap: () => context.go('/inventory/${p.id}'),
          cells: [
            // Product name & image
            DataCell(
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.imageUrl.isNotEmpty
                        ? Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            // SKU
            DataCell(Text(p.sku,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textMuted))),
            // Stock
            DataCell(Row(children: [
              Text('$stock ${p.unit}'),
              if (isLowStock)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.warning, color: Colors.orange, size: 14),
                ),
            ])),
            // Expiry with quick adjust button
            DataCell(
              Tooltip(
                message: 'Click to adjust expiry date',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _showUpdateExpiryDialog(context, p, expiryDateVal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(expiryText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.expiryStatus == 'Expired'
                                      ? AppColors.statusRed
                                      : item.expiryStatus == 'Expiring Soon'
                                          ? AppColors.statusAmber
                                          : null,
                                )),
                            const SizedBox(height: 2),
                            expiryBadge,
                          ],
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_calendar_outlined, size: 15, color: AppColors.primary.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Cost Price
            DataCell(Text(
              currFmt.format(p.cost),
              style: const TextStyle(fontWeight: FontWeight.w600),
            )),
            // Inventory Value = Cost * Stock Quantity
            DataCell(Text(
              currFmt.format(invValue),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.accentTeal,
              ),
            )),
            // Selling price
            DataCell(Text(currFmt.format(p.price))),
            // Stock status badge
            DataCell(stockBadge),
            // Actions (Details + Delete)
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => context.go('/inventory/${p.id}'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.statusRed,
                    tooltip: 'Delete Product',
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
                        if (context.mounted) {
                          toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            title: const Text('Product Deleted'),
                            description: Text('${p.name} was removed.'),
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
