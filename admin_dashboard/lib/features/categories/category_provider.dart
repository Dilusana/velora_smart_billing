import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'category_repository.dart';

// ---------------------------------------------------------------------------
// Repository Provider
// ---------------------------------------------------------------------------
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// ---------------------------------------------------------------------------
// Firestore-backed CategoriesNotifier
// Subscribes to a real-time Firestore stream so the UI stays in sync
// whenever categories are added, updated, or deleted.
// ---------------------------------------------------------------------------
class FirestoreCategoriesNotifier
    extends AsyncNotifier<List<CategoryModel>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  Future<List<CategoryModel>> build() async {
    // Subscribe to Firestore stream and rebuild state whenever it emits.
    final stream = _repo.getCategories();
    final subscription = stream.listen((updated) {
      state = AsyncData(updated);
    }, onError: (e) {
      state = AsyncError(e, StackTrace.current);
    });
    ref.onDispose(() => subscription.cancel());

    // Wait for the first snapshot to return the initial data.
    return stream.first;
  }

  /// Add a new category to Firestore.
  /// The repo generates the ID on the Firestore side; the stream will sync back.
  Future<void> add(CategoryModel category) async {
    try {
      await _repo.addCategory(category);
    } catch (e) {
      // Surface the error without losing existing state
      final current = state.value ?? [];
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Update an existing category in Firestore.
  /// Optimistic local update so the UI feels instant.
  Future<void> updateCategory(CategoryModel category) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final c in current) if (c.id == category.id) category else c,
    ]);
    try {
      await _repo.updateCategory(category);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Delete a category from Firestore.
  /// Optimistic local update so the UI feels instant.
  Future<void> delete(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
    try {
      await _repo.deleteCategory(id);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// The main categories provider used throughout the app.
final categoriesFirestoreProvider =
    AsyncNotifierProvider<FirestoreCategoriesNotifier, List<CategoryModel>>(
  FirestoreCategoriesNotifier.new,
);