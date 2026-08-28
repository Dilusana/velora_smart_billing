import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../categories/category_provider.dart';
import '../products/product_providers.dart';
import '../suppliers/supplier_providers.dart';
import '../../providers/app_providers.dart';
import 'inventory_providers.dart';
import 'inventory_repository.dart';

class InventoryDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const InventoryDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  ConsumerState<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends ConsumerState<InventoryDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(firestoreProductsProvider);

    return productsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (products) {
        final product = products.where((p) => p.id == widget.productId).firstOrNull;
        if (product == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Product not found', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.go('/inventory'), child: const Text('Back to Inventory')),
              ]),
            ),
          );
        }
        return _buildPage(context, product, isDark);
      },
    );
  }

  Widget _buildPage(BuildContext context, ProductModel product, bool isDark) {
    final batchesAsync = ref.watch(stockBatchesByProductProvider(product.id));
    final fifoAsync = ref.watch(productFifoStatsProvider(product.id));
    final currentBatchCost = fifoAsync.value?.fifoCostPrice;

    // Compute expiry status from product or batches
    DateTime? earliestExpiry = product.expiryDate;
    String expiryStatus = 'N/A';
    batchesAsync.whenData((batches) {
      final active = batches.where((b) => b.status == 'active');
      if (active.isNotEmpty) {
        final batchExpiry = active.map((b) => b.expiryDate).reduce((a, b) => a.isBefore(b) ? a : b);
        earliestExpiry ??= batchExpiry;
      }
    });

    if (earliestExpiry != null) {
      final diff = earliestExpiry!.difference(DateTime.now()).inDays;
      expiryStatus = diff < 0 ? 'Expired' : diff <= 5 ? 'Expiring Soon' : 'Normal';
    }

    final int activeBatches = batchesAsync.value?.where((b) => b.status == 'active').length ?? 0;

    final categoriesAsync = ref.watch(categoriesFirestoreProvider);
    final categories = categoriesAsync.value ?? [];
    final categoryObj = categories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == product.category || c?.name.toLowerCase() == product.category.toLowerCase(),
      orElse: () => null,
    );
    final categoryName = categoryObj?.name ?? (product.category.isNotEmpty ? product.category : 'Uncategorized');

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Breadcrumb header ────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => context.go('/inventory'),
                ),
                TextButton(
                  onPressed: () => context.go('/inventory'),
                  child: const Text('Inventory', style: TextStyle(color: AppColors.primary)),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Product info card ─────────────────────────────────────────
            _ProductInfoCard(
              product: product, 
              categoryName: categoryName,
              expiryStatus: expiryStatus, 
              earliestExpiry: earliestExpiry,
              currentBatchCost: currentBatchCost,
              onUpdateExpiry: () => _showUpdateExpiryDialog(context, product, earliestExpiry),
            ),
            const SizedBox(height: 16),

            // ── Summary stat row ─────────────────────────────────────────
            _SummaryStatRow(
              productId: product.id,
              stock: product.stock,
              unit: product.unit,
              activeBatches: activeBatches,
              earliestExpiry: earliestExpiry,
              expiryStatus: expiryStatus,
              cost: product.cost,
            ),
            const SizedBox(height: 20),

            // ── Tabs ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(child: Row(children: [Icon(Icons.receipt_long, size: 14), SizedBox(width: 6), Text('Purchase History')])),
                      Tab(child: Row(children: [Icon(Icons.point_of_sale, size: 14), SizedBox(width: 6), Text('Sale History')])),
                      Tab(child: Row(children: [Icon(Icons.tune, size: 14), SizedBox(width: 6), Text('Stock Adjustments')])),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () => _showAddStockDialog(context, product),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Adjust Stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () => _showAdjustStockDialog(context, product),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tab content ───────────────────────────────────────────────
            Card(
              elevation: 0,
              color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: [
                _PurchaseHistoryTab(productId: product.id),
                _SaleHistoryTab(productId: product.id),
                _AdjustmentHistoryTab(productId: product.id),
              ][_tabController.index],
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _showUpdateExpiryDialog(
      BuildContext context, ProductModel product, DateTime? currentExpiry) async {
    final dateFmt = DateFormat('dd MMM yyyy');
    DateTime? selectedDate = product.expiryDate ?? currentExpiry;

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

  // ── Add Stock Dialog ───────────────────────────────────────────────────────
  void _showAddStockDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => _AddStockDialog(product: product),
    );
  }

  // ── Adjust Stock Dialog ────────────────────────────────────────────────────
  void _showAdjustStockDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => _AdjustStockDialog(product: product),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProductInfoCard extends StatelessWidget {
  final ProductModel product;
  final String categoryName;
  final String expiryStatus;
  final DateTime? earliestExpiry;
  final double? currentBatchCost;
  final VoidCallback? onUpdateExpiry;
  const _ProductInfoCard({
    required this.product,
    required this.categoryName,
    required this.expiryStatus,
    required this.earliestExpiry,
    this.currentBatchCost,
    this.onUpdateExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image / Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  _StatusBadge(status: product.status),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 24, runSpacing: 6, children: [
                  _InfoChip(label: 'SKU', value: product.sku, icon: Icons.qr_code),
                  _InfoChip(label: 'Category', value: categoryName, icon: Icons.category_outlined),
                  _InfoChip(label: 'Unit', value: product.unit, icon: Icons.straighten),
                  _InfoChip(label: 'Sale Price', value: 'Rs. ${product.price.toStringAsFixed(2)}', icon: Icons.sell_outlined),
                  _InfoChip(label: 'Cost Price', value: 'Rs. ${product.cost.toStringAsFixed(2)}', icon: Icons.shopping_cart_outlined),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onUpdateExpiry,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _InfoChip(
                            label: 'Expiry Date',
                            value: earliestExpiry != null ? DateFormat('dd MMM yyyy').format(earliestExpiry!) : 'Not Set',
                            icon: Icons.event_outlined,
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_calendar_outlined, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.statusGreenBg : AppColors.statusGrayBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status,
          style: TextStyle(
            color: isActive ? AppColors.statusGreen : AppColors.statusGray,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoChip({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Stat Row
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryStatRow extends ConsumerWidget {
  final String productId;
  final int stock, activeBatches;
  final String unit, expiryStatus;
  final DateTime? earliestExpiry;
  final double cost;
  const _SummaryStatRow({
    required this.productId,
    required this.stock,
    required this.unit,
    required this.activeBatches,
    required this.earliestExpiry,
    required this.expiryStatus,
    required this.cost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    Color expiryColor = AppColors.statusGreen;
    Color expiryBg = AppColors.statusGreenBg;
    if (expiryStatus == 'Expired') { expiryColor = AppColors.statusRed; expiryBg = AppColors.statusRedBg; }
    if (expiryStatus == 'Expiring Soon') { expiryColor = AppColors.statusAmber; expiryBg = AppColors.statusAmberBg; }
    if (expiryStatus == 'N/A') { expiryColor = AppColors.statusGray; expiryBg = AppColors.statusGrayBg; }

    final double invValueNum = cost * stock;
    final invValue = currFmt.format(invValueNum);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          icon: FontAwesomeIcons.boxesStacked,
          label: 'Total Stock',
          value: '$stock $unit',
          color: AppColors.primary,
          bg: AppColors.primary.withValues(alpha: 0.08),
        ),
        _StatCard(
          icon: FontAwesomeIcons.layerGroup,
          label: 'Active Batches',
          value: '$activeBatches',
          color: AppColors.accentTeal,
          bg: AppColors.accentTeal.withValues(alpha: 0.08),
        ),
        _StatCard(
          icon: FontAwesomeIcons.calendarXmark,
          label: 'Earliest Expiry',
          value: earliestExpiry != null ? dateFmt.format(earliestExpiry!) : '—',
          color: expiryColor,
          bg: expiryBg,
        ),
        _StatCard(
          icon: FontAwesomeIcons.circleCheck,
          label: 'Expiry Status',
          value: expiryStatus,
          color: expiryColor,
          bg: expiryBg,
        ),
        _StatCard(
          icon: FontAwesomeIcons.sackDollar,
          label: 'Inventory Value',
          value: invValue,
          color: AppColors.accentTeal,
          bg: AppColors.accentTeal.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bg;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: FaIcon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase History Tab
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseHistoryTab extends ConsumerWidget {
  final String productId;
  const _PurchaseHistoryTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(stockBatchesByProductProvider(productId));
    final dateFmt = DateFormat('dd MMM yyyy');

    return batchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (batches) {
        if (batches.isEmpty) {
          return _EmptyState(
            icon: FontAwesomeIcons.receipt,
            message: 'No purchase history yet',
            sub: 'Click "Add Stock" to record a stock purchase',
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${batches.length} purchase record(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(0.8),
                  4: FlexColumnWidth(0.8),
                  5: FlexColumnWidth(1),
                  6: FlexColumnWidth(1),
                  7: FlexColumnWidth(1),
                  8: FlexColumnWidth(1),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
                children: [
                  _tableHeader(['Batch #', 'Supplier', 'Supplier ID', 'Orig. Qty', 'Remaining', 'Purchase Price', 'Purchase Date', 'Production Date', 'Expiry Date']),
                  ...batches.map((b) => _tableRow([
                    b.batchNumber,
                    b.supplierName,
                    b.supplierId,
                    '${b.quantity} units',
                    '${b.remainingQty} units',
                    'Rs. ${b.purchasePrice.toStringAsFixed(2)}',
                    dateFmt.format(b.purchaseDate),
                    dateFmt.format(b.productionDate),
                    dateFmt.format(b.expiryDate),
                  ], highlight: b.expiryStatus, batchStatus: b.status, context: context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  TableRow _tableHeader(List<String> cols) {
    return TableRow(
      decoration: BoxDecoration(color: AppColors.bgPrimary),
      children: cols.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
      )).toList(),
    );
  }

  TableRow _tableRow(List<String> vals,
      {String highlight = 'Normal', String batchStatus = 'active', required BuildContext context}) {
    Color? rowColor;
    if (highlight == 'Expired') rowColor = AppColors.statusRedBg;
    if (highlight == 'Expiring Soon') rowColor = AppColors.statusAmberBg;
    if (batchStatus == 'depleted') rowColor = AppColors.statusGrayBg;

    return TableRow(
      decoration: rowColor != null ? BoxDecoration(color: rowColor.withOpacity(0.3)) : null,
      children: vals.asMap().entries.map((e) {
        // Index 4 = Remaining Qty — style depleted batches
        final isRemaining = e.key == 4;
        Widget child = Text(e.value, style: const TextStyle(fontSize: 13));
        if (isRemaining && batchStatus == 'depleted') {
          child = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.statusGrayBg, borderRadius: BorderRadius.circular(10)),
            child: Text('Depleted', style: const TextStyle(color: AppColors.statusGray, fontWeight: FontWeight.bold, fontSize: 11)),
          );
        }
        // Last column = expiry date — highlight if expiring
        final isLast = e.key == vals.length - 1;
        if (isLast && highlight != 'Normal') {
          Color c = highlight == 'Expired' ? AppColors.statusRed : AppColors.statusAmber;
          Color bg = highlight == 'Expired' ? AppColors.statusRedBg : AppColors.statusAmberBg;
          child = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Text(e.value, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: child,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sale History Tab — enriched FIFO data from sale_line_items
// ─────────────────────────────────────────────────────────────────────────────
class _SaleHistoryTab extends ConsumerWidget {
  final String productId;
  const _SaleHistoryTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleLineItemsByProductProvider(productId));
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sales) {
        if (sales.isEmpty) {
          return _EmptyState(
            icon: FontAwesomeIcons.cashRegister,
            message: 'No sales recorded yet',
            sub: 'Sales will appear here when orders are placed or completed',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sales.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header row
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${sales.length} sale record(s)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              );
            }
            final sale = sales[index - 1];
            final profitColor =
                sale.profit >= 0 ? AppColors.statusGreen : AppColors.statusRed;
            return _SaleLineItemCard(
              sale: sale,
              currFmt: currFmt,
              dateFmt: dateFmt,
              profitColor: profitColor,
            );
          },
        );
      },
    );
  }
}

class _SaleLineItemCard extends StatefulWidget {
  final SaleLineItemModel sale;
  final NumberFormat currFmt;
  final DateFormat dateFmt;
  final Color profitColor;
  const _SaleLineItemCard({
    required this.sale,
    required this.currFmt,
    required this.dateFmt,
    required this.profitColor,
  });

  @override
  State<_SaleLineItemCard> createState() => _SaleLineItemCardState();
}

class _SaleLineItemCardState extends State<_SaleLineItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.sale;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          // ── Main info row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(spacing: 20, runSpacing: 8, children: [
                    _SaleChip(
                      label: 'Order',
                      value: '#${s.orderId.toUpperCase().substring(0, s.orderId.length.clamp(0, 8))}',
                      icon: Icons.receipt_outlined,
                    ),
                    _SaleChip(
                      label: 'Date',
                      value: widget.dateFmt.format(s.saleDate),
                      icon: Icons.calendar_today_outlined,
                    ),
                    _SaleChip(
                      label: 'Qty',
                      value: '${s.quantitySold} units',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _SaleChip(
                      label: 'Revenue',
                      value: widget.currFmt.format(s.totalRevenue),
                      icon: Icons.sell_outlined,
                    ),
                    _SaleChip(
                      label: 'COGS',
                      value: widget.currFmt.format(s.cogs),
                      icon: Icons.shopping_cart_outlined,
                      valueColor: AppColors.statusAmber,
                    ),
                    _SaleChip(
                      label: 'Profit',
                      value: widget.currFmt.format(s.profit),
                      icon: Icons.trending_up,
                      valueColor: widget.profitColor,
                    ),
                  ]),
                ),
                if (s.batchConsumptions.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                    tooltip: 'Batch breakdown',
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
              ],
            ),
          ),

          // ── Batch breakdown accordion ───────────────────────────────
          if (_expanded && s.batchConsumptions.isNotEmpty) ...
            [
              Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch Breakdown',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                      },
                      border: TableBorder(
                        horizontalInside:
                            BorderSide(color: AppColors.border.withOpacity(0.4)),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppColors.bgPrimary),
                          children: ['Batch #', 'Qty Used', 'Unit Cost', 'Total Cost']
                              .map((h) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    child: Text(h,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                        ...s.batchConsumptions.map((bc) => TableRow(
                              children: [
                                bc.batchNumber,
                                '${bc.quantityConsumed} units',
                                widget.currFmt.format(bc.unitCostPrice),
                                widget.currFmt.format(bc.totalCost),
                              ]
                                  .map((v) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Text(v,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _SaleChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;
  const _SaleChip({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: valueColor)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Adjustment History Tab
// ─────────────────────────────────────────────────────────────────────────────
class _AdjustmentHistoryTab extends ConsumerWidget {
  final String productId;
  const _AdjustmentHistoryTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjAsync = ref.watch(adjustmentsByProductProvider(productId));
    final dateFmt = DateFormat('dd MMM yyyy HH:mm');

    return adjAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (adjustments) {
        if (adjustments.isEmpty) {
          return _EmptyState(
            icon: FontAwesomeIcons.sliders,
            message: 'No adjustments recorded',
            sub: 'Click "Adjust Stock" to manually update stock levels',
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${adjustments.length} adjustment(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(0.8),
                  2: FlexColumnWidth(0.8),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.5),
                  5: FlexColumnWidth(1.2),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
                children: [
                  _tableHeader(['Date & Time', 'Type', 'Quantity', 'Reason', 'Notes', 'Adjusted By']),
                  ...adjustments.map((a) => _tableRow(
                    date: dateFmt.format(a.createdAt),
                    type: a.type,
                    qty: a.quantity,
                    reason: a.reason,
                    notes: a.notes,
                    by: a.adjustedBy,
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  TableRow _tableHeader(List<String> cols) {
    return TableRow(
      decoration: BoxDecoration(color: AppColors.bgPrimary),
      children: cols.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
      )).toList(),
    );
  }

  TableRow _tableRow({
    required String date,
    required String type,
    required int qty,
    required String reason,
    required String notes,
    required String by,
  }) {
    final isAdd = type == 'add';
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(date, style: const TextStyle(fontSize: 12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAdd ? AppColors.statusGreenBg : AppColors.statusRedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(isAdd ? '+ Add' : '- Remove',
                style: TextStyle(
                    color: isAdd ? AppColors.statusGreen : AppColors.statusRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text('$qty units', style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAdd ? AppColors.statusGreen : AppColors.statusRed))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(reason, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(notes.isEmpty ? '—' : notes,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(by, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Stock Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _AddStockDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const _AddStockDialog({required this.product});

  @override
  ConsumerState<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<_AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _expiryDaysCtrl = TextEditingController();

  String? _selectedSupplierId;
  String? _selectedSupplierName;
  DateTime _purchaseDate = DateTime.now();
  DateTime _productionDate = DateTime.now();
  DateTime? _calculatedExpiryDate;
  bool _loading = false;

  void _onExpiryDaysChanged(String val) {
    final days = int.tryParse(val);
    setState(() {
      _calculatedExpiryDate =
          days != null ? _productionDate.add(Duration(days: days)) : null;
    });
  }

  void _onProductionDateChanged(DateTime date) {
    final days = int.tryParse(_expiryDaysCtrl.text);
    setState(() {
      _productionDate = date;
      _calculatedExpiryDate =
          days != null ? _productionDate.add(Duration(days: days)) : null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      _showError('Please select a supplier');
      return;
    }
    if (_calculatedExpiryDate == null) {
      _showError('Please enter expiry duration');
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final batchNumber =
          'BATCH-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final batch = StockBatchModel(
        id: '',
        productId: widget.product.id,
        productName: widget.product.name,
        supplierId: _selectedSupplierId!,
        supplierName: _selectedSupplierName!,
        quantity: int.parse(_qtyCtrl.text),
        remainingQty: int.parse(_qtyCtrl.text),
        purchasePrice: double.parse(_priceCtrl.text),
        purchaseDate: _purchaseDate,
        productionDate: _productionDate,
        expiryDate: _calculatedExpiryDate!,
        expiryDays: int.parse(_expiryDaysCtrl.text),
        batchNumber: batchNumber,
        status: 'active',
        createdAt: now,
      );

      await ref.read(inventoryRepositoryProvider).addStockBatch(batch);

      if (!mounted) return;
      final nav = Navigator.of(context);
      final ctx = context;
      nav.pop();
      toastification.show(
        context: ctx,
        type: ToastificationType.success,
        title: const Text('Stock added successfully'),
        description: Text('$batchNumber · ${int.parse(_qtyCtrl.text)} units added'),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to add stock: $e');
    }
  }

  void _showError(String msg) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _expiryDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreSuppliersAsync = ref.watch(firestoreSuppliersProvider);
    final List<SupplierModel> suppliers = firestoreSuppliersAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : ref.watch(suppliersProvider),
      orElse: () => ref.watch(suppliersProvider),
    );
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add Stock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(widget.product.name,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ]),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Supplier dropdown
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'Supplier *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                items: suppliers.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    s.companyName.isNotEmpty ? s.companyName : s.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (val) {
                  final sup = suppliers.firstWhere((s) => s.id == val);
                  setState(() {
                    _selectedSupplierId = val;
                    _selectedSupplierName = sup.companyName.isNotEmpty ? sup.companyName : sup.name;
                  });
                },
                validator: (v) => v == null ? 'Please select a supplier' : null,
              ),
              const SizedBox(height: 16),

              // Qty + Price row
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Must be a number';
                      if (int.parse(v) < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price (Rs.) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Purchase date + Production date row
              Row(children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Purchase Date *',
                    value: _purchaseDate,
                    icon: Icons.calendar_today,
                    onChanged: (d) => setState(() => _purchaseDate = d),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: 'Production Date *',
                    value: _productionDate,
                    icon: Icons.factory_outlined,
                    onChanged: _onProductionDateChanged,
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Expiry duration → auto-calc expiry date
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryDaysCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Duration (days) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.hourglass_bottom),
                      hintText: 'e.g. 30',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _onExpiryDaysChanged,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Must be a whole number';
                      if (int.parse(v) < 1) return 'Min 1 day';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Auto-calculated expiry date display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _calculatedExpiryDate != null
                          ? AppColors.statusGreenBg
                          : AppColors.statusGrayBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _calculatedExpiryDate != null
                            ? AppColors.statusGreen.withOpacity(0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calculated Expiry Date',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(
                            _calculatedExpiryDate != null
                                ? Icons.event_available
                                : Icons.event_outlined,
                            size: 18,
                            color: _calculatedExpiryDate != null
                                ? AppColors.statusGreen
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _calculatedExpiryDate != null
                                ? dateFmt.format(_calculatedExpiryDate!)
                                : 'Enter duration above',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _calculatedExpiryDate != null
                                  ? AppColors.statusGreen
                                  : AppColors.textMuted,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Actions
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add Stock'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjust Stock Dialog — supports direct Balance Stock and FIFO batch consumption
// ─────────────────────────────────────────────────────────────────────────────
class _AdjustStockDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const _AdjustStockDialog({required this.product});

  @override
  ConsumerState<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<_AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'add'; // 'add' or 'remove'
  String _targetMode = 'balance'; // 'balance' or 'fifo'
  String? _reason;
  bool _loading = false;

  // FIFO batch state
  List<FifoBatchConsumption>? _batchPreview;
  bool _previewLoading = false;
  String? _previewError;
  int _availableBatchStock = 0;

  static const _addReasons = ['Restock', 'Return', 'Correction', 'Physical Count Adjustment', 'Other'];
  static const _removeReasons = ['Expired', 'Damage', 'Spoiled', 'Waste', 'Correction', 'Shrinkage / Loss', 'Other'];

  @override
  void initState() {
    super.initState();
    _checkBatchStock();
  }

  Future<void> _checkBatchStock() async {
    try {
      final batches = await ref.read(inventoryRepositoryProvider).getBatchesForProduct(widget.product.id).first;
      final activeBatches = batches.where((b) => b.status == 'active' && b.remainingQty > 0);
      final total = activeBatches.fold<int>(0, (sum, b) => sum + b.remainingQty);
      if (mounted) {
        setState(() {
          _availableBatchStock = total;
          if (total > 0) {
            _targetMode = 'fifo';
          } else {
            _targetMode = 'balance';
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFifoPreview() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 1 || _targetMode != 'fifo') {
      setState(() { _batchPreview = null; _previewError = null; });
      return;
    }
    setState(() { _previewLoading = true; _previewError = null; });
    try {
      final consumptions = await ref
          .read(inventoryRepositoryProvider)
          .previewFifoConsumption(widget.product.id, qty);
      if (mounted) setState(() { _batchPreview = consumptions; _previewLoading = false; });
    } on InsufficientStockException catch (e) {
      if (mounted) {
        setState(() {
          _previewError = 'Only ${e.available} units available in active FIFO batches.\nSwitch to "Balance Stock" to adjust directly from catalog inventory.';
          _previewLoading = false;
          _batchPreview = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _previewError = 'Preview failed: $e'; _previewLoading = false; _batchPreview = null; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reason == null) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Please select a reason'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    final int qty = int.parse(_qtyCtrl.text.trim());

    if (_type == 'remove') {
      if (qty > widget.product.stock) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Invalid Quantity'),
          description: Text('Cannot remove $qty units. Total current stock is only ${widget.product.stock} ${widget.product.unit}.'),
          autoCloseDuration: const Duration(seconds: 4),
        );
        return;
      }

      if (_targetMode == 'fifo' && _availableBatchStock > 0) {
        if (_batchPreview == null) {
          await _loadFifoPreview();
        }
        if (_batchPreview == null && _availableBatchStock < qty) {
          _targetMode = 'balance';
        }
      }
    }

    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final adjustedBy = auth.currentUser?.name ?? 'Admin';

      final adjustment = StockAdjustmentModel(
        id: '',
        productId: widget.product.id,
        productName: widget.product.name,
        type: _type,
        quantity: qty,
        reason: _reason!,
        notes: _notesCtrl.text.trim(),
        adjustedBy: adjustedBy,
        createdAt: DateTime.now(),
      );

      final isUsingFifo = _type == 'remove' && _targetMode == 'fifo' && _batchPreview != null && _batchPreview!.isNotEmpty;

      await ref.read(inventoryRepositoryProvider).addAdjustment(
        adjustment,
        batchConsumptions: isUsingFifo ? _batchPreview! : [],
      );

      if (!mounted) return;
      final nav = Navigator.of(context);
      final ctx = context;
      nav.pop();
      toastification.show(
        context: ctx,
        type: ToastificationType.success,
        title: const Text('Stock adjusted successfully'),
        description: Text(
          _type == 'add'
              ? 'Added $qty ${widget.product.unit} to stock.'
              : 'Deducted $qty ${widget.product.unit} from ${isUsingFifo ? "FIFO batches" : "balance stock"}.',
        ),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Error: $e'),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = _type == 'add' ? _addReasons : _removeReasons;
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final int enteredQty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final int projectedStock = _type == 'add'
        ? widget.product.stock + enteredQty
        : (widget.product.stock - enteredQty).clamp(0, 999999);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Adjust Stock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 12),

                // Current stock & batch summary banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('SKU: ${widget.product.sku} | Unit: ${widget.product.unit}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Balance: ${widget.product.stock} ${widget.product.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text('Batches: $_availableBatchStock units',
                              style: TextStyle(
                                fontSize: 12,
                                color: _availableBatchStock > 0 ? AppColors.statusGreen : AppColors.textMuted,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Type toggle (Add vs Remove)
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _type = 'add'; _reason = null; _batchPreview = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'add' ? AppColors.statusGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == 'add' ? AppColors.statusGreen : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('+ Add Stock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == 'add' ? Colors.white : AppColors.textMuted,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _type = 'remove'; _reason = null; _batchPreview = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'remove' ? AppColors.statusRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == 'remove' ? AppColors.statusRed : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('- Remove Stock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == 'remove' ? Colors.white : AppColors.textMuted,
                            )),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Stock Source Selection (Balance Stock vs FIFO Batch) ───
                if (_type == 'remove') ...[
                  const Text('Adjust From:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _targetMode = 'balance';
                              _batchPreview = null;
                              _previewError = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _targetMode == 'balance'
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _targetMode == 'balance' ? AppColors.primary : AppColors.border,
                                width: _targetMode == 'balance' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _targetMode == 'balance' ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 16,
                                  color: _targetMode == 'balance' ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Balance Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('${widget.product.stock} ${widget.product.unit} available',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _availableBatchStock > 0
                              ? () {
                                  setState(() {
                                    _targetMode = 'fifo';
                                  });
                                  _loadFifoPreview();
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Opacity(
                            opacity: _availableBatchStock > 0 ? 1.0 : 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _targetMode == 'fifo'
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _targetMode == 'fifo' ? AppColors.primary : AppColors.border,
                                  width: _targetMode == 'fifo' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _targetMode == 'fifo' ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 16,
                                    color: _targetMode == 'fifo' ? AppColors.primary : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('FIFO Batches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text('$_availableBatchStock units in batches',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Quantity & Reason
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setState(() {});
                        if (_type == 'remove' && _targetMode == 'fifo') {
                          _loadFifoPreview();
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final num = int.tryParse(v.trim());
                        if (num == null) return 'Must be a number';
                        if (num < 1) return 'Min 1';
                        if (_type == 'remove' && num > widget.product.stock) {
                          return 'Exceeds stock (${widget.product.stock})';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _reason,
                      decoration: const InputDecoration(
                        labelText: 'Reason *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: reasons
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() { _reason = v; });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),

                // ── Preview Box (Balance Stock vs FIFO) ──────────────────────
                const SizedBox(height: 16),
                if (_type == 'remove' && _targetMode == 'fifo' && _availableBatchStock > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusAmberBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusAmber.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.statusAmber),
                          SizedBox(width: 6),
                          Text('FIFO Batch Consumption Breakdown',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.statusAmber)),
                        ]),
                        const SizedBox(height: 8),
                        if (_previewLoading)
                          const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_previewError != null)
                          Text(_previewError!,
                              style: const TextStyle(color: AppColors.statusRed, fontSize: 12))
                        else if (_batchPreview != null && _batchPreview!.isNotEmpty) ...[
                          ..._batchPreview!.map((bc) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(bc.batchNumber,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text(
                                          '${bc.quantityConsumed} units × ${currFmt.format(bc.unitCostPrice)} = ${currFmt.format(bc.totalCost)}',
                                          style: const TextStyle(fontSize: 12)),
                                    ]),
                              )),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(
                                currFmt.format(_batchPreview!.fold<double>(0, (s, bc) => s + bc.totalCost)),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ] else
                          const Text('Enter quantity to see batch breakdown.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _type == 'add' ? Icons.trending_up : Icons.inventory_2_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _type == 'add' ? 'Balance Stock Addition' : 'Direct Balance Stock Adjustment',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Current: ${widget.product.stock} ${widget.product.unit}  ➔  New Balance: $projectedStock ${widget.product.unit}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _type == 'add' ? AppColors.statusGreen : AppColors.statusRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_type == 'add' ? 'Confirm Add' : 'Confirm Remove'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker Field
// ─────────────────────────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final IconData icon;
  final ValueChanged<DateTime> onChanged;
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.calendar_month_outlined),
          ),
          controller: TextEditingController(text: fmt.format(value)),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: FaIcon(icon, size: 36, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(sub,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
