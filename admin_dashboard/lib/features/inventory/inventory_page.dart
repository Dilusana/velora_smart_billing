import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
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

    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
            ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.fileImport, size: 16),
              label: const Text('Bulk Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onPressed: () {},
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
      headingRowColor: WidgetStateProperty.all(
        isDark ? AppColors.bgDarkSurface : AppColors.bgPrimary,
      ),
      columnSpacing: 16,
      columns: const [
        DataColumn2(label: Text('Product Name'), size: ColumnSize.L),
        DataColumn2(label: Text('SKU'), size: ColumnSize.S),
        DataColumn2(label: Text('Stock'), size: ColumnSize.S),
        DataColumn2(label: Text('Expiry'), size: ColumnSize.M),
        DataColumn2(label: Text('FIFO Cost'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Inv. Value'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Sell Price'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Est. Profit'), size: ColumnSize.S, numeric: true),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text(''), size: ColumnSize.S),
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

        final expiryText = item.earliestExpiry != null
            ? dateFmt.format(item.earliestExpiry!)
            : '—';

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
            // Expiry
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expiryText,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.expiryStatus == 'Expired'
                          ? AppColors.statusRed
                          : item.expiryStatus == 'Expiring Soon'
                              ? AppColors.statusAmber
                              : null,
                    )),
                expiryBadge,
              ],
            )),
            // FIFO Cost Price — loaded lazily per row
            DataCell(_FifoStatCell(
              productId: p.id,
              builder: (FifoProductStats stats) => Text(
                currFmt.format(stats.fifoCostPrice),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )),
            // Inventory Value
            DataCell(_FifoStatCell(
              productId: p.id,
              builder: (FifoProductStats stats) => Text(
                currFmt.format(stats.inventoryValue),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentTeal,
                ),
              ),
            )),
            // Selling price (from product doc — no FIFO needed)
            DataCell(Text(currFmt.format(p.price))),
            // Est. Profit
            DataCell(_FifoStatCell(
              productId: p.id,
              builder: (FifoProductStats stats) {
                final positive = stats.estimatedProfit >= 0;
                return Text(
                  currFmt.format(stats.estimatedProfit),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: positive ? AppColors.statusGreen : AppColors.statusRed,
                  ),
                );
              },
            )),
            // Stock status badge
            DataCell(stockBadge),
            // Details button
            DataCell(
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
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------------------------------------------------------------------
// Lazy FIFO stat cell — watches productFifoStatsProvider only for its product
// ---------------------------------------------------------------------------

class _FifoStatCell extends ConsumerWidget {
  final String productId;
  final Widget Function(FifoProductStats stats) builder;

  const _FifoStatCell({
    required this.productId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(productFifoStatsProvider(productId));
    return statsAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      error: (_, __) => const Text('—',
          style: TextStyle(color: AppColors.textMuted)),
      data: builder,
    );
  }
}
