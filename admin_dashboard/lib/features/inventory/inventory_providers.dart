import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import '../products/product_providers.dart';
import 'inventory_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

// ---------------------------------------------------------------------------
// All stock batches (real-time stream)
// ---------------------------------------------------------------------------
final allStockBatchesProvider =
    StreamProvider<List<StockBatchModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getAllBatches();
});

// ---------------------------------------------------------------------------
// Stock batches for a single product (family)
// ---------------------------------------------------------------------------
final stockBatchesByProductProvider =
    StreamProvider.family<List<StockBatchModel>, String>((ref, productId) {
  return ref.watch(inventoryRepositoryProvider).getBatchesForProduct(productId);
});

// ---------------------------------------------------------------------------
// All stock adjustments (real-time stream)
// ---------------------------------------------------------------------------
final allStockAdjustmentsProvider =
    StreamProvider<List<StockAdjustmentModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getAllAdjustments();
});

// ---------------------------------------------------------------------------
// Stock adjustments for a single product (family)
// ---------------------------------------------------------------------------
final adjustmentsByProductProvider =
    StreamProvider.family<List<StockAdjustmentModel>, String>((ref, productId) {
  return ref
      .watch(inventoryRepositoryProvider)
      .getAdjustmentsForProduct(productId);
});

// ---------------------------------------------------------------------------
// Sale history for a single product — legacy (family)
// Reads from the orders collection. Kept for backward compat.
// ---------------------------------------------------------------------------
final saleHistoryByProductProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, productId) {
  return ref
      .watch(inventoryRepositoryProvider)
      .getSaleHistoryForProduct(productId);
});

// ---------------------------------------------------------------------------
// FIFO-enriched sale line items for a single product (family)
// Reads from the sale_line_items collection.
// ---------------------------------------------------------------------------
final saleLineItemsByProductProvider =
    StreamProvider.family<List<SaleLineItemModel>, String>((ref, productId) {
  return ref
      .watch(inventoryRepositoryProvider)
      .getSaleLineItemsForProduct(productId);
});

// ---------------------------------------------------------------------------
// FIFO product stats for a single product (family)
// Requires the product's selling price — looked up from firestoreProductsProvider.
// ---------------------------------------------------------------------------
final productFifoStatsProvider =
    StreamProvider.family<FifoProductStats, String>((ref, productId) {
  // Watch the products list to get the current selling price
  final productsAsync = ref.watch(firestoreProductsProvider);
  final sellingPrice = productsAsync.maybeWhen(
    data: (products) {
      final product = products.where((p) => p.id == productId).firstOrNull;
      return product?.price ?? 0.0;
    },
    orElse: () => 0.0,
  );

  return ref
      .watch(inventoryRepositoryProvider)
      .getProductFifoStats(productId, sellingPrice);
});

// ---------------------------------------------------------------------------
// Inventory with expiry data — merges products + batches
// Returns a list of [ProductWithExpiry] for the main inventory table.
// ---------------------------------------------------------------------------

class ProductWithExpiry {
  final ProductModel product;
  final DateTime? earliestExpiry; // null = no batches with expiry
  final String expiryStatus;     // 'Normal' | 'Expiring Soon' | 'Expired' | 'N/A'

  const ProductWithExpiry({
    required this.product,
    required this.earliestExpiry,
    required this.expiryStatus,
  });
}

String _calcExpiryStatus(DateTime? date) {
  if (date == null) return 'N/A';
  final diff = date.difference(DateTime.now()).inDays;
  if (diff < 0) return 'Expired';
  if (diff <= 5) return 'Expiring Soon';
  return 'Normal';
}

final inventoryWithExpiryProvider =
    Provider<AsyncValue<List<ProductWithExpiry>>>((ref) {
  final productsAsync = ref.watch(firestoreProductsProvider);
  final batchesAsync = ref.watch(allStockBatchesProvider);

  return productsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (products) => batchesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
      data: (batches) {
        // Group batches by productId, pick earliest expiry
        final Map<String, DateTime?> earliestExpiry = {};
        for (final batch in batches) {
          if (batch.status == 'active') {
            final existing = earliestExpiry[batch.productId];
            if (existing == null || batch.expiryDate.isBefore(existing)) {
              earliestExpiry[batch.productId] = batch.expiryDate;
            }
          }
        }

        return AsyncValue.data(products.map((p) {
          final expiry = earliestExpiry[p.id];
          return ProductWithExpiry(
            product: p,
            earliestExpiry: expiry,
            expiryStatus: _calcExpiryStatus(expiry),
          );
        }).toList());
      },
    ),
  );
});
