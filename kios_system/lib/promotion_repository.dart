import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'product_model.dart';
import 'promotion_model.dart';

class CouponValidationResult {
  final bool isValid;
  final double discount;
  final String message;
  final PromotionModel? promotion;

  const CouponValidationResult({
    required this.isValid,
    this.discount = 0.0,
    required this.message,
    this.promotion,
  });
}

class KioskPromotionRepository {
  static final KioskPromotionRepository instance = KioskPromotionRepository._();

  KioskPromotionRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _promotionsRef => _firestore.collection('Promotion');

  /// Streams active promotions in real-time from Firestore with fallback
  Stream<List<PromotionModel>> getPromotionsStream() {
    return _promotionsRef.snapshots().asyncMap((snapshot) async {
      var docs = snapshot.docs;
      if (docs.isEmpty) {
        try {
          final snapLower = await _firestore.collection('promotions').get();
          if (snapLower.docs.isNotEmpty) {
            docs = snapLower.docs;
          }
        } catch (_) {}
      }

      final list = docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .where((promo) => promo.isActive)
          .toList();

      list.sort((a, b) => b.startDate.compareTo(a.startDate));

      if (list.isEmpty) {
        return PromotionModel.fallbackPromotions;
      }
      return list;
    }).handleError((error) {
      debugPrint('Error streaming kiosk promotions: $error');
      return PromotionModel.fallbackPromotions;
    });
  }

  /// Get active promotions once (for quick checks)
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      var snap = await _promotionsRef.get();
      var docs = snap.docs;
      if (docs.isEmpty) {
        final snapLower = await _firestore.collection('promotions').get();
        if (snapLower.docs.isNotEmpty) {
          docs = snapLower.docs;
        }
      }

      final list = docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {}
    return PromotionModel.fallbackPromotions;
  }

  /// Validates a coupon code against active Firestore promotions
  Future<CouponValidationResult> validateCouponCode(
    String code,
    double subtotal,
  ) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return const CouponValidationResult(
        isValid: false,
        message: 'Please enter a coupon code',
      );
    }

    final activePromos = await getActivePromotions();
    PromotionModel? matchedPromo;

    for (final promo in activePromos) {
      final pCode = promo.couponCode.trim().toUpperCase();
      final pId = promo.id.trim().toUpperCase();
      final pName = promo.name.trim().toUpperCase();
      if (pCode == cleanCode || pId == cleanCode || pName == cleanCode) {
        matchedPromo = promo;
        break;
      }
    }

    // Support standard fallback codes if not matched
    if (matchedPromo == null) {
      if (cleanCode == 'SAVE5' || cleanCode == 'KIOSK5') {
        return const CouponValidationResult(
          isValid: true,
          discount: 2.50,
          message: 'Promo code applied: Rs. 2.50 off',
        );
      }
      return const CouponValidationResult(
        isValid: false,
        message: 'Invalid or expired promo code',
      );
    }

    // Check minimum purchase amount
    if (matchedPromo.minimumPurchaseAmount > 0 &&
        subtotal < matchedPromo.minimumPurchaseAmount) {
      return CouponValidationResult(
        isValid: false,
        message:
            'Min. spend Rs.${matchedPromo.minimumPurchaseAmount.toStringAsFixed(0)} required for this offer',
        promotion: matchedPromo,
      );
    }

    // Calculate discount value
    double computedDiscount = 0.0;
    final type = matchedPromo.type.toLowerCase();

    if (type.contains('percent') || type.contains('%') || type == 'discount %') {
      computedDiscount = subtotal * (matchedPromo.value / 100.0);
    } else if (type.contains('flat') || type == 'flat off') {
      computedDiscount = matchedPromo.value;
    } else if (type.contains('bogo')) {
      // 50% discount equivalent for BOGO if applied on total
      computedDiscount = subtotal * 0.5;
    } else {
      // General value
      if (matchedPromo.value > 0 && matchedPromo.value <= 100) {
        computedDiscount = subtotal * (matchedPromo.value / 100.0);
      } else {
        computedDiscount = matchedPromo.value;
      }
    }

    // Cap at maximum discount if set
    if (matchedPromo.maximumDiscount > 0 &&
        computedDiscount > matchedPromo.maximumDiscount) {
      computedDiscount = matchedPromo.maximumDiscount;
    }

    // Discount cannot exceed subtotal
    computedDiscount = computedDiscount.clamp(0.0, subtotal);

    return CouponValidationResult(
      isValid: true,
      discount: computedDiscount,
      message:
          '${matchedPromo.name} applied! (Saved Rs.${computedDiscount.toStringAsFixed(0)})',
      promotion: matchedPromo,
    );
  }

  /// Checks if a product matches any active promotion
  PromotionModel? getPromotionForProduct(
    ProductModel product,
    List<PromotionModel> activePromotions,
  ) {
    for (final promo in activePromotions) {
      if (!promo.isActive) continue;

      if (promo.scope == 'All Products') {
        return promo;
      }

      if (promo.scope == 'Specific Category' || promo.applicableCategories.isNotEmpty) {
        final matchesCat = promo.applicableCategories.any((cat) =>
            cat.trim().toLowerCase() == product.category.trim().toLowerCase() ||
            cat.trim().toLowerCase() == product.categoryId.trim().toLowerCase());
        if (matchesCat) return promo;
      }

      if (promo.scope == 'Specific Products' || promo.applicableProducts.isNotEmpty) {
        final matchesProd = promo.applicableProducts.any((pid) =>
            pid.trim() == product.id.trim() ||
            pid.trim().toLowerCase() == product.name.trim().toLowerCase());
        if (matchesProd) return promo;
      }
    }
    return null;
  }
}
