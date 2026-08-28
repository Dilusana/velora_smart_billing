import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'product_repository.dart';

// ---------------------------------------------------------------------------
// Repository Provider
// ---------------------------------------------------------------------------
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ---------------------------------------------------------------------------
// Firestore-backed ProductsNotifier
// Combines a real-time Firestore stream for initial/background sync with
// optimistic local updates so the UI stays instant on add/update/delete.
// ---------------------------------------------------------------------------
class FirestoreProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  ProductRepository get _repo => ref.read(productRepositoryProvider);

  @override
  Future<List<ProductModel>> build() async {
    // Subscribe to Firestore stream and rebuild state whenever it emits.
    final stream = _repo.getProducts();
    final subscription = stream.listen((updated) {
      state = AsyncData(updated);
    }, onError: (e, st) {
      state = AsyncError(e, st);
    });
    ref.onDispose(() => subscription.cancel());
    return stream.first;
  }

  /// Add a new product to Firestore and update local state immediately.
  Future<void> add(ProductModel product) async {
    // Optimistic update
    final current = state.value ?? [];
    state = AsyncData([...current, product]);
    try {
      await _repo.addProduct(product);
    } catch (e) {
      // Roll back on error
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Update an existing product in Firestore and update local state immediately.
  Future<void> updateProduct(ProductModel product) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current) if (p.id == product.id) product else p,
    ]);
    try {
      await _repo.updateProduct(product);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Delete a product from Firestore and update local state immediately.
  Future<void> delete(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
    try {
      await _repo.deleteProduct(id);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Delete multiple products from Firestore and update local state immediately.
  Future<void> batchDelete(List<String> ids) async {
    final current = state.value ?? [];
    final idSet = ids.toSet();
    state = AsyncData(current.where((p) => !idSet.contains(p.id)).toList());
    try {
      await _repo.batchDeleteProducts(ids);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// The main products provider used throughout the app.
final firestoreProductsProvider =
    AsyncNotifierProvider<FirestoreProductsNotifier, List<ProductModel>>(
  FirestoreProductsNotifier.new,
);