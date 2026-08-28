import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import 'product_providers.dart';

class DuplicateGroup {
  final String key;
  final String title;
  final List<ProductModel> products;
  final String keepId;

  DuplicateGroup({
    required this.key,
    required this.title,
    required this.products,
    required this.keepId,
  });
}

class DuplicateProductsDialog extends ConsumerStatefulWidget {
  final List<ProductModel> allProducts;

  const DuplicateProductsDialog({Key? key, required this.allProducts}) : super(key: key);

  @override
  ConsumerState<DuplicateProductsDialog> createState() => _DuplicateProductsDialogState();
}

class _DuplicateProductsDialogState extends ConsumerState<DuplicateProductsDialog> {
  final Set<String> _selectedToDelete = {};
  List<DuplicateGroup> _duplicateGroups = [];
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _detectDuplicates();
  }

  void _detectDuplicates() {
    final Map<String, List<ProductModel>> groupsMap = {};

    for (final p in widget.allProducts) {
      final nameKey = 'name:${p.name.trim().toLowerCase()}';
      groupsMap.putIfAbsent(nameKey, () => []).add(p);
    }

    final List<DuplicateGroup> detected = [];
    final Set<String> alreadyGroupedDocIds = {};

    for (final entry in groupsMap.entries) {
      if (entry.value.length > 1) {
        final list = entry.value;
        for (final item in list) {
          alreadyGroupedDocIds.add(item.id);
        }

        // Determine which one is best to keep:
        // Priority: 1. Higher stock, 2. Has expiry date, 3. Non-empty description
        ProductModel keepCandidate = list.first;
        for (final candidate in list) {
          if (candidate.stock > keepCandidate.stock) {
            keepCandidate = candidate;
          } else if (candidate.stock == keepCandidate.stock) {
            if (candidate.expiryDate != null && keepCandidate.expiryDate == null) {
              keepCandidate = candidate;
            }
          }
        }

        detected.add(DuplicateGroup(
          key: entry.key,
          title: list.first.name,
          products: list,
          keepId: keepCandidate.id,
        ));
      }
    }

    // Also check for matching SKUs (for items not already grouped by identical name)
    final Map<String, List<ProductModel>> skuMap = {};
    for (final p in widget.allProducts) {
      final sku = p.sku.trim().toLowerCase();
      if (sku.isNotEmpty && !alreadyGroupedDocIds.contains(p.id)) {
        skuMap.putIfAbsent(sku, () => []).add(p);
      }
    }

    for (final entry in skuMap.entries) {
      if (entry.value.length > 1) {
        final list = entry.value;
        ProductModel keepCandidate = list.first;
        for (final candidate in list) {
          if (candidate.stock > keepCandidate.stock) {
            keepCandidate = candidate;
          }
        }
        detected.add(DuplicateGroup(
          key: 'sku:${entry.key}',
          title: 'SKU: ${list.first.sku}',
          products: list,
          keepId: keepCandidate.id,
        ));
      }
    }

    // Pre-select all non-keep items for deletion
    _selectedToDelete.clear();
    for (final g in detected) {
      for (final p in g.products) {
        if (p.id != g.keepId) {
          _selectedToDelete.add(p.id);
        }
      }
    }

    setState(() {
      _duplicateGroups = detected;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedToDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusRed),
            SizedBox(width: 10),
            Text('Confirm Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedToDelete.length} duplicate product entries? This cannot be undone.',
        ),
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final idsList = _selectedToDelete.toList();
      await ref.read(firestoreProductsProvider.notifier).batchDelete(idsList);

      if (mounted) {
        Navigator.pop(context);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Duplicates Deleted'),
          description: Text('Successfully removed ${idsList.length} duplicate product entries.'),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to Delete Duplicates'),
          description: Text(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy');
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 840,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clean Duplicate Products',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _duplicateGroups.isEmpty
                              ? 'No duplicates found in product catalog'
                              : 'Found ${_duplicateGroups.length} duplicate groups (${_selectedToDelete.length} marked for removal)',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Body ──────────────────────────────────────────────────────────
            Expanded(
              child: _duplicateGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, size: 64, color: AppColors.statusGreen),
                          SizedBox(height: 16),
                          Text(
                            'All Clean!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No duplicate products or SKUs detected in your database.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _duplicateGroups.length,
                      itemBuilder: (context, gIndex) {
                        final group = _duplicateGroups[gIndex];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: isDark ? AppColors.bgDarkSurface : AppColors.bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? AppColors.bgDarkBorder : AppColors.border,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 16, color: AppColors.statusAmber),
                                    const SizedBox(width: 8),
                                    Text(
                                      group.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusAmberBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${group.products.length} copies',
                                        style: const TextStyle(
                                          color: AppColors.statusAmber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...group.products.map((p) {
                                  final isKeep = p.id == group.keepId;
                                  final isCheckedForDelete = _selectedToDelete.contains(p.id);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isKeep
                                          ? AppColors.statusGreenBg.withValues(alpha: 0.4)
                                          : (isCheckedForDelete
                                              ? AppColors.statusRedBg.withValues(alpha: 0.3)
                                              : (isDark ? AppColors.bgDark : AppColors.bgPrimary)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isKeep
                                            ? AppColors.statusGreen.withValues(alpha: 0.4)
                                            : (isCheckedForDelete
                                                ? AppColors.statusRed.withValues(alpha: 0.3)
                                                : Colors.transparent),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isCheckedForDelete,
                                          activeColor: AppColors.statusRed,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedToDelete.add(p.id);
                                              } else {
                                                _selectedToDelete.remove(p.id);
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 16,
                                            runSpacing: 6,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'SKU: ',
                                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                  ),
                                                  Text(
                                                    p.sku.isNotEmpty ? p.sku : '(none)',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Stock: ',
                                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                  ),
                                                  Text(
                                                    '${p.stock} ${p.unit}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: p.stock > 0 ? AppColors.statusGreen : AppColors.statusRed,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Cost: ',
                                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                  ),
                                                  Text(
                                                    currFmt.format(p.cost),
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Price: ',
                                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                  ),
                                                  Text(
                                                    currFmt.format(p.price),
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              if (p.expiryDate != null)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.event_outlined, size: 12, color: AppColors.textMuted),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      dateFmt.format(p.expiryDate!),
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isKeep)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusGreenBg,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'KEEP (Best)',
                                              style: TextStyle(
                                                color: AppColors.statusGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusRedBg,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'DUPLICATE',
                                              style: TextStyle(
                                                color: AppColors.statusRed,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Actions Footer ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_duplicateGroups.isNotEmpty)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedToDelete.clear();
                            for (final g in _duplicateGroups) {
                              for (final p in g.products) {
                                if (p.id != g.keepId) {
                                  _selectedToDelete.add(p.id);
                                }
                              }
                            }
                          });
                        },
                        child: const Text('Select All Redundant'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedToDelete.clear()),
                        child: const Text('Deselect All'),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    if (_duplicateGroups.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onPressed: _isDeleting || _selectedToDelete.isEmpty ? null : _deleteSelected,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: Text(
                          _isDeleting
                              ? 'Deleting...'
                              : 'Delete ${_selectedToDelete.length} Selected Duplicates',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
