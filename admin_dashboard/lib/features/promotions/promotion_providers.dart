import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'promotion_repository.dart';

// ---------------------------------------------------------------------------
// Repository Provider
// ---------------------------------------------------------------------------
final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository();
});

// ---------------------------------------------------------------------------
// Firestore-backed Promotions Notifier
// ---------------------------------------------------------------------------
class FirestorePromotionsNotifier extends AsyncNotifier<List<PromotionModel>> {
  PromotionRepository get _repo => ref.read(promotionRepositoryProvider);

  @override
  Future<List<PromotionModel>> build() async {
    final stream = _repo.getPromotions();
    final promotions = await stream.first;

    stream.listen((updated) {
      if (!state.isLoading) {
        state = AsyncData(updated);
      }
    });

    return promotions;
  }

  /// Add a new promotion to Firestore
  Future<void> add(PromotionModel promo) async {
    final current = state.value ?? [];
    state = AsyncData([...current, promo]);
    try {
      await _repo.addPromotion(promo);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Update an existing promotion in Firestore
  Future<void> updatePromo(PromotionModel promo) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current) if (p.id == promo.id) promo else p,
    ]);
    try {
      await _repo.updatePromotion(promo);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Toggle promotion status (active / inactive)
  Future<void> toggleStatus(String id, bool isActive) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == id) p.copyWith(status: isActive ? 'active' : 'inactive') else p,
    ]);
    try {
      await _repo.toggleStatus(id, isActive);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Delete a promotion
  Future<void> delete(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
    try {
      await _repo.deletePromotion(id);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final firestorePromotionsProvider =
    AsyncNotifierProvider<FirestorePromotionsNotifier, List<PromotionModel>>(
  FirestorePromotionsNotifier.new,
);
