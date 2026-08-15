import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

// ---------------------------------------------------------------------------
// Custom Exceptions
// ---------------------------------------------------------------------------

class InsufficientStockException implements Exception {
  final String productId;
  final int requested;
  final int available;

  InsufficientStockException({
    required this.productId,
    required this.requested,
    required this.available,
  });

  @override
  String toString() =>
      'InsufficientStockException: requested $requested units for product $productId, '
      'but only $available units available.';
}

// ---------------------------------------------------------------------------
// Inventory Repository
// ---------------------------------------------------------------------------

class InventoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _batches => _db.collection('stock_batches');
  CollectionReference get _adjustments => _db.collection('stock_adjustments');
  CollectionReference get _products => _db.collection('products');
  CollectionReference get _saleLineItems => _db.collection('sale_line_items');

  // -------------------------------------------------------------------------
  // Stock Batches
  // -------------------------------------------------------------------------

  /// Real-time stream of ALL stock batches (used for deriving expiry per product)
  Stream<List<StockBatchModel>> getAllBatches() {
    return _batches.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) =>
              StockBatchModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Sort client-side to avoid requiring a composite Firestore index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of stock batches for a single product
  Stream<List<StockBatchModel>> getBatchesForProduct(String productId) {
    return _batches
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              StockBatchModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Sort client-side: newest first for UI display
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add a new stock batch AND increment the product's stock count atomically
  Future<void> addStockBatch(StockBatchModel batch) async {
    final WriteBatch wb = _db.batch();

    // 1. Write batch document
    final batchRef = _batches.doc();
    wb.set(batchRef, batch.toMap());

    // 2. Increment product stock
    final productRef = _products.doc(batch.productId);
    wb.update(productRef, {'stock': FieldValue.increment(batch.quantity)});

    await wb.commit();
  }

  // -------------------------------------------------------------------------
  // FIFO Sale Processing
  // -------------------------------------------------------------------------

  /// Processes a FIFO stock deduction for a single product within a sale.
  ///
  /// Uses a two-phase approach required by Firestore transactions:
  /// - Phase 1: Query active batches sorted by purchaseDate (outside transaction).
  /// - Phase 2: Re-read each batch by ID inside a transaction and apply FIFO writes.
  ///
  /// Throws [InsufficientStockException] if available stock < [quantitySold].
  Future<FifoSaleResult> processFifoSale({
    required String productId,
    required String productName,
    required int quantitySold,
    required double sellingPricePerUnit,
    required String orderId,
  }) async {
    // ── Phase 1: Fetch active batches ordered oldest-first (outside transaction) ─
    final snapshot = await _batches
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active')
        .orderBy('purchaseDate')
        .get();

    final activeBatches = snapshot.docs
        .map((doc) =>
            StockBatchModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((b) => b.remainingQty > 0)
        .toList();

    // Verify sufficient stock before entering transaction
    final totalAvailable =
        activeBatches.fold<int>(0, (acc, b) => acc + b.remainingQty);
    if (totalAvailable < quantitySold) {
      throw InsufficientStockException(
        productId: productId,
        requested: quantitySold,
        available: totalAvailable,
      );
    }

    // ── Phase 2: Atomically deduct from batches inside a Firestore transaction ─
    FifoSaleResult? result;

    await _db.runTransaction((txn) async {
      int remaining = quantitySold;
      double totalCogs = 0.0;
      final consumptions = <FifoBatchConsumption>[];

      for (final batch in activeBatches) {
        if (remaining <= 0) break;

        // Re-read the batch document inside the transaction for consistency
        final batchRef = _batches.doc(batch.id);
        final batchSnap = await txn.get(batchRef);
        if (!batchSnap.exists) continue;

        final currentData = batchSnap.data() as Map<String, dynamic>;
        final currentRemaining = (currentData['remainingQty'] as num?)?.toInt() ?? 0;
        if (currentRemaining <= 0) continue;

        final consume = remaining < currentRemaining ? remaining : currentRemaining;
        final newRemaining = currentRemaining - consume;
        final batchCost = consume * batch.purchasePrice;

        consumptions.add(FifoBatchConsumption(
          batchId: batch.id,
          batchNumber: batch.batchNumber,
          quantityConsumed: consume,
          unitCostPrice: batch.purchasePrice,
          totalCost: batchCost,
        ));

        totalCogs += batchCost;
        remaining -= consume;

        // Update batch remainingQty; deplete if exhausted
        txn.update(batchRef, {
          'remainingQty': newRemaining,
          if (newRemaining == 0) 'status': 'depleted',
        });
      }

      final totalRevenue = quantitySold * sellingPricePerUnit;
      final profit = totalRevenue - totalCogs;

      // Decrement product stock
      final productRef = _products.doc(productId);
      txn.update(productRef, {'stock': FieldValue.increment(-quantitySold)});

      // Write sale_line_items document atomically
      final saleRef = _saleLineItems.doc();
      txn.set(saleRef, SaleLineItemModel(
        id: saleRef.id,
        orderId: orderId,
        productId: productId,
        productName: productName,
        quantitySold: quantitySold,
        sellingPrice: sellingPricePerUnit,
        totalRevenue: totalRevenue,
        cogs: totalCogs,
        profit: profit,
        saleDate: DateTime.now(),
        batchConsumptions: consumptions,
      ).toMap());

      result = FifoSaleResult(
        cogs: totalCogs,
        profit: profit,
        totalRevenue: totalRevenue,
        batchConsumptions: consumptions,
      );
    });

    return result!;
  }

  /// Processes FIFO deductions for every item in a completed [OrderModel].
  ///
  /// This is called when an order's status transitions to 'Completed'.
  /// Each product is processed with its own FIFO transaction.
  Future<void> processFifoSaleForOrder(OrderModel order) async {
    for (final item in order.items) {
      await processFifoSale(
        productId: item.productId,
        productName: item.productName,
        quantitySold: item.quantity,
        sellingPricePerUnit: item.unitPrice,
        orderId: order.id,
      );
    }
  }

  // -------------------------------------------------------------------------
  // FIFO Statistics
  // -------------------------------------------------------------------------

  /// Stream of FIFO statistics for a single product.
  ///
  /// Combines active batch data (for cost/value) with sale_line_items (for
  /// cumulative COGS). Emits whenever either source changes.
  Stream<FifoProductStats> getProductFifoStats(
      String productId, double sellingPrice) {
    // Combine two streams: active batches + sale line items
    final batchStream = _batches
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active')
        .snapshots();

    // Return a computed stream — COGS totals are fetched via one-time get() inside asyncMap
    return batchStream.asyncMap((batchSnap) async {
      final batches = batchSnap.docs
          .map((d) => StockBatchModel.fromMap(
              d.id, d.data() as Map<String, dynamic>))
          .where((b) => b.remainingQty > 0)
          .toList();

      // Compute batch-derived stats
      int currentStock = 0;
      double inventoryValue = 0.0;

      // Sort batches by purchaseDate to find the oldest (first batch)
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

      for (final b in batches) {
        currentStock += b.remainingQty;
        inventoryValue += b.remainingQty * b.purchasePrice;
      }

      final fifoCostPrice = batches.isNotEmpty ? batches.first.purchasePrice : 0.0;

      // Fetch cumulative COGS from sale_line_items (one-time fetch inside stream)
      final saleSnap = await _saleLineItems
          .where('productId', isEqualTo: productId)
          .get();

      double totalCogsToDate = 0.0;
      for (final doc in saleSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalCogsToDate += (data['cogs'] as num?)?.toDouble() ?? 0.0;
      }

      final estimatedProfit =
          (sellingPrice - fifoCostPrice) * currentStock;

      return FifoProductStats(
        currentStock: currentStock,
        fifoCostPrice: fifoCostPrice,
        inventoryValue: inventoryValue,
        sellingPrice: sellingPrice,
        totalCogsToDate: totalCogsToDate,
        estimatedProfit: estimatedProfit,
      );
    });
  }

  /// Stream of FIFO-enriched sale records for a product.
  Stream<List<SaleLineItemModel>> getSaleLineItemsForProduct(String productId) {
    return _saleLineItems
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => SaleLineItemModel.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      return list;
    });
  }

  // -------------------------------------------------------------------------
  // FIFO Batch Consumption Preview (for Adjust Stock dialog)
  // -------------------------------------------------------------------------

  /// Computes which FIFO batches would be consumed for a given removal quantity.
  /// Used to show a preview before committing an adjustment.
  Future<List<FifoBatchConsumption>> previewFifoConsumption(
      String productId, int quantity) async {
    final snapshot = await _batches
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active')
        .orderBy('purchaseDate')
        .get();

    final activeBatches = snapshot.docs
        .map((doc) =>
            StockBatchModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((b) => b.remainingQty > 0)
        .toList();

    final totalAvailable =
        activeBatches.fold<int>(0, (acc, b) => acc + b.remainingQty);
    if (totalAvailable < quantity) {
      throw InsufficientStockException(
        productId: productId,
        requested: quantity,
        available: totalAvailable,
      );
    }

    int remaining = quantity;
    final consumptions = <FifoBatchConsumption>[];

    for (final batch in activeBatches) {
      if (remaining <= 0) break;
      final consume = remaining < batch.remainingQty ? remaining : batch.remainingQty;
      consumptions.add(FifoBatchConsumption(
        batchId: batch.id,
        batchNumber: batch.batchNumber,
        quantityConsumed: consume,
        unitCostPrice: batch.purchasePrice,
        totalCost: consume * batch.purchasePrice,
      ));
      remaining -= consume;
    }

    return consumptions;
  }

  // -------------------------------------------------------------------------
  // Stock Adjustments
  // -------------------------------------------------------------------------

  /// Real-time stream of ALL stock adjustments across all products
  Stream<List<StockAdjustmentModel>> getAllAdjustments() {
    return _adjustments.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => StockAdjustmentModel.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Sort client-side: newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of adjustments for a single product
  Stream<List<StockAdjustmentModel>> getAdjustmentsForProduct(
      String productId) {
    return _adjustments
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => StockAdjustmentModel.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Sort client-side: newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add an adjustment AND update the product stock atomically.
  ///
  /// For FIFO-consuming removal reasons (Damage, Expired, Spoiled, Waste):
  ///   - Pass [batchConsumptions] computed via [previewFifoConsumption].
  ///   - The method updates affected batch remainingQty values.
  ///
  /// For non-FIFO reasons (Correction, Return, Other):
  ///   - [batchConsumptions] is empty; only product stock is updated.
  Future<void> addAdjustment(
    StockAdjustmentModel adjustment, {
    List<FifoBatchConsumption> batchConsumptions = const [],
  }) async {
    final WriteBatch wb = _db.batch();

    // 1. Write adjustment document (with optional batch consumption data)
    final adjRef = _adjustments.doc();
    wb.set(
      adjRef,
      adjustment
          .copyWith(batchConsumptions: batchConsumptions)
          .toMap(),
    );

    // 2. Increment or decrement product stock
    final delta =
        adjustment.type == 'add' ? adjustment.quantity : -adjustment.quantity;
    final productRef = _products.doc(adjustment.productId);
    wb.update(productRef, {'stock': FieldValue.increment(delta)});

    // 3. For FIFO-consuming removals, update each consumed batch
    if (adjustment.type == 'remove' && batchConsumptions.isNotEmpty) {
      for (final consumption in batchConsumptions) {
        final batchRef = _batches.doc(consumption.batchId);
        // We can't read inside a WriteBatch, so we pre-fetch the current remainingQty
        // The caller (dialog) should have already computed this via previewFifoConsumption
        wb.update(batchRef, {
          'remainingQty': FieldValue.increment(-consumption.quantityConsumed),
        });
        // Note: status update to 'depleted' for batches that reach 0 is handled
        // separately in a follow-up write if needed. Since WriteBatch can't read,
        // we use a transaction for the full FIFO adjustment.
      }
    }

    await wb.commit();

    // 4. For FIFO removals, do a follow-up pass to mark depleted batches.
    //    This is a best-effort update; the core stock numbers are already committed.
    if (adjustment.type == 'remove' && batchConsumptions.isNotEmpty) {
      final depletedIds = <String>[];
      for (final consumption in batchConsumptions) {
        final doc = await _batches.doc(consumption.batchId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final remaining = (data['remainingQty'] as num?)?.toInt() ?? 0;
          if (remaining <= 0) depletedIds.add(consumption.batchId);
        }
      }
      if (depletedIds.isNotEmpty) {
        final depletedBatch = _db.batch();
        for (final id in depletedIds) {
          depletedBatch.update(_batches.doc(id), {'status': 'depleted'});
        }
        await depletedBatch.commit();
      }
    }
  }

  // -------------------------------------------------------------------------
  // Sale History (legacy — from orders collection)
  // -------------------------------------------------------------------------

  /// Returns all order documents that contain at least one item with [productId].
  /// Kept for backward compatibility; prefer [getSaleLineItemsForProduct].
  Stream<List<Map<String, dynamic>>> getSaleHistoryForProduct(
      String productId) {
    return _db.collection('orders').snapshots().map((snap) {
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          if ((item as Map<String, dynamic>)['productId'] == productId) {
            results.add({
              'orderId': doc.id,
              'createdAt': data['createdAt'],
              'quantity': item['quantity'],
              'unitPrice': item['unitPrice'],
              'total': item['total'],
            });
            break;
          }
        }
      }
      // Sort newest first client-side
      results.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
        final bDate =
            DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return results;
    });
  }
}
