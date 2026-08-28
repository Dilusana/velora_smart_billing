import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import 'cart_service.dart';
import 'user_activity_service.dart';

/// Transparent, scoring-based recommendation engine for the Velora Supermarket application
class RecommendationService {
  static final RecommendationService instance = RecommendationService._internal();

  RecommendationService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Cross-category complementary pairs for cross-selling
  static const Map<String, List<String>> _complementaryCategories = {
    'vegetables & fruits': ['grocery', 'chilled foods', 'beverages'],
    'vegetables': ['grocery', 'chilled foods'],
    'fruits': ['chilled foods', 'beverages', 'dairy'],
    'grocery': ['chilled foods', 'beverages', 'household', 'vegetables & fruits'],
    'beverages': ['grocery', 'snacks', 'chilled foods'],
    'chilled foods': ['grocery', 'beverages', 'vegetables & fruits'],
    'frozen foods': ['beverages', 'grocery', 'household'],
    'household': ['grocery', 'beverages'],
    'dairy': ['grocery', 'beverages', 'chilled foods'],
  };

  /// ═════════════════════════════════════════════════════════════════════════
  /// 1. PERSONALIZED RECOMMENDATIONS ("Recommended for You")
  /// ═════════════════════════════════════════════════════════════════════════
  Future<List<ProductModel>> getPersonalizedRecommendations({
    String? userId,
    int limit = 8,
    List<ProductModel>? availablePool,
  }) async {
    String? uid = userId;
    if (uid == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid;
        }
      } catch (_) {}
    }

    final allProducts = availablePool ?? await _getAllAvailableProducts();

    if (allProducts.isEmpty) {
      return ProductRepository.fallbackProducts.take(limit).toList();
    }

    // Cold start / Guest User check: Fallback to popular products
    if (uid == null || uid.isEmpty || uid == 'guest_session') {
      return getPopularProducts(limit: limit, availablePool: allProducts);
    }

    try {
      // 1. Fetch User's Previous Orders
      final pastOrders = await _fetchUserOrders(uid);

      // 2. Fetch User's Recent Activities
      final recentActivities = await UserActivityService.instance.getRecentActivities(
        userId: uid,
        limit: 40,
      );

      // 3. Current items in Cart (to avoid recommending what they already have)
      final currentCartTitles = CartService.instance.items
          .map((i) => i.title.trim().toLowerCase())
          .toSet();

      // If user has zero purchase history and zero activity -> Cold start fallback
      if (pastOrders.isEmpty && recentActivities.isEmpty) {
        return getPopularProducts(limit: limit, availablePool: allProducts);
      }

      // 4. Calculate Category Affinity Frequency
      final Map<String, double> categoryWeights = {};
      final Set<String> pastPurchasedProductNames = {};
      final Set<String> recentPurchasedWithin24h = {};

      final now = DateTime.now();

      // Order items contribution
      for (final order in pastOrders) {
        final orderAgeDays = order.createdAt != null
            ? now.difference(order.createdAt!).inDays
            : 30;
        final recencyMultiplier = orderAgeDays < 7
            ? 1.5
            : (orderAgeDays < 30 ? 1.0 : 0.7);

        for (final item in order.items) {
          final pNameLower = item.productName.trim().toLowerCase();
          pastPurchasedProductNames.add(pNameLower);

          if (orderAgeDays <= 1) {
            recentPurchasedWithin24h.add(pNameLower);
          }

          // Find product category from allProducts
          final matchingProduct = allProducts.firstWhere(
            (p) => p.name.trim().toLowerCase() == pNameLower || p.id == item.productId,
            orElse: () => const ProductModel(
              id: '',
              name: '',
              description: '',
              category: 'General',
              price: 0,
              stock: 0,
              imageUrl: '',
              status: 'active',
            ),
          );

          final catKey = matchingProduct.category.toLowerCase().trim();
          if (catKey.isNotEmpty && catKey != 'general') {
            categoryWeights[catKey] = (categoryWeights[catKey] ?? 0) + (3.0 * recencyMultiplier);
          }
        }
      }

      // Recent Activity contribution
      final Set<String> recentlyViewedCategories = {};
      final Set<String> recentlyViewedProductNames = {};

      for (final act in recentActivities) {
        final daysAgo = now.difference(act.timestamp).inDays;
        final timeDecay = daysAgo < 2 ? 1.5 : (daysAgo < 7 ? 1.0 : 0.5);

        if (act.categoryName.isNotEmpty) {
          final catKey = act.categoryName.toLowerCase().trim();
          categoryWeights[catKey] = (categoryWeights[catKey] ?? 0) + (1.5 * timeDecay);
          if (daysAgo < 3) recentlyViewedCategories.add(catKey);
        }

        if (act.productName.isNotEmpty && daysAgo < 7) {
          recentlyViewedProductNames.add(act.productName.toLowerCase().trim());
        }
      }

      // 5. Score Each Candidate Product
      final List<MapEntry<ProductModel, double>> scoredProducts = [];

      for (final product in allProducts) {
        final pNameLower = product.name.trim().toLowerCase();
        final pCatLower = product.category.trim().toLowerCase();

        double score = 0.0;

        // Penalty: Out of Stock or Inactive
        if (!product.isActive || product.stock <= 0) {
          score -= 100.0;
        }

        // Penalty: Already in current cart
        if (currentCartTitles.contains(pNameLower)) {
          score -= 20.0;
        }

        // Penalty: Purchased in last 24 hours (avoid immediate repeated recommendation)
        if (recentPurchasedWithin24h.contains(pNameLower)) {
          score -= 15.0;
        }

        // Bonus: Preferred Category Affinity (+5 * weight)
        if (categoryWeights.containsKey(pCatLower)) {
          score += (categoryWeights[pCatLower]! * 1.5).clamp(2.0, 15.0);
        }

        // Bonus: Similar to recently viewed product (+4)
        if (recentlyViewedProductNames.any((viewed) => _isProductSimilar(viewed, pNameLower, pCatLower))) {
          score += 4.0;
        }

        // Bonus: Product in a recently viewed category (+2)
        if (recentlyViewedCategories.contains(pCatLower)) {
          score += 2.5;
        }

        // Bonus: Similar to a previously purchased product (+5)
        if (pastPurchasedProductNames.any((purchased) => _isProductSimilar(purchased, pNameLower, pCatLower))) {
          score += 4.5;
        }

        // Bonus: Popular / Featured Product (+3)
        if (product.isFeatured) {
          score += 3.0;
        }

        // Bonus: Discount / Special Price (+2)
        if (product.originalPrice != null && product.originalPrice! > product.price) {
          score += 2.0;
        }

        // Stock availability confidence (+1)
        if (product.stock > 10) {
          score += 1.0;
        }

        if (score > 0.0) {
          scoredProducts.add(MapEntry(product, score));
        }
      }

      // 6. Sort by Final Recommendation Score Descending
      scoredProducts.sort((a, b) => b.value.compareTo(a.value));

      final List<ProductModel> results = scoredProducts.map((e) => e.key).toList();

      // If results are fewer than requested limit, fill with popular products (no duplicates)
      if (results.length < limit) {
        final popular = await getPopularProducts(limit: limit, availablePool: allProducts);
        for (final p in popular) {
          if (!results.any((r) => r.id == p.id || r.name == p.name)) {
            results.add(p);
          }
          if (results.length >= limit) break;
        }
      }

      return results.take(limit).toList();
    } catch (e) {
      debugPrint('[RecommendationService] getPersonalizedRecommendations error: $e');
      return getPopularProducts(limit: limit, availablePool: allProducts);
    }
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// 2. SIMILAR PRODUCTS ("You May Also Like")
  /// ═════════════════════════════════════════════════════════════════════════
  Future<List<ProductModel>> getSimilarProducts({
    required ProductModel targetProduct,
    int limit = 6,
    List<ProductModel>? availablePool,
  }) async {
    final allProducts = availablePool ?? await _getAllAvailableProducts();
    final targetNameLower = targetProduct.name.trim().toLowerCase();
    final targetCatLower = targetProduct.category.trim().toLowerCase();

    final List<MapEntry<ProductModel, double>> candidates = [];

    for (final product in allProducts) {
      // Exclude self and out of stock
      if (product.id == targetProduct.id || product.name.toLowerCase() == targetNameLower) continue;
      if (!product.isActive || product.stock <= 0) continue;

      final pNameLower = product.name.trim().toLowerCase();
      final pCatLower = product.category.trim().toLowerCase();

      double simScore = 0.0;

      // Same exact category (+8)
      if (pCatLower == targetCatLower) {
        simScore += 8.0;
      }

      // Keyword / Subcategory match in product name (+5)
      if (_hasKeywordOverlap(targetNameLower, pNameLower)) {
        simScore += 5.0;
      }

      // Similar Price Bracket (+2)
      if (targetProduct.price > 0) {
        final priceDiff = (product.price - targetProduct.price).abs();
        final priceRatio = priceDiff / targetProduct.price;
        if (priceRatio < 0.3) {
          simScore += 2.5;
        } else if (priceRatio < 0.6) {
          simScore += 1.0;
        }
      }

      // Popularity boost (+2)
      if (product.isFeatured) {
        simScore += 2.0;
      }

      if (simScore > 0.0) {
        candidates.add(MapEntry(product, simScore));
      }
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final results = candidates.map((e) => e.key).toList();

    // Fallback if not enough similar products
    if (results.length < limit) {
      final popular = await getPopularProducts(limit: limit, availablePool: allProducts);
      for (final p in popular) {
        if (p.id != targetProduct.id && !results.any((r) => r.id == p.id)) {
          results.add(p);
        }
        if (results.length >= limit) break;
      }
    }

    return results.take(limit).toList();
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// 3. CART CROSS-SELLING ("Complete Your Order")
  /// ═════════════════════════════════════════════════════════════════════════
  Future<List<ProductModel>> getCartRecommendations({
    List<CartItem>? cartItems,
    int limit = 6,
    List<ProductModel>? availablePool,
  }) async {
    final items = cartItems ?? CartService.instance.items;
    final allProducts = availablePool ?? await _getAllAvailableProducts();

    if (items.isEmpty) {
      return getPopularProducts(limit: limit, availablePool: allProducts);
    }

    final cartTitles = items.map((i) => i.title.trim().toLowerCase()).toSet();
    final cartCategories = items.map((i) => i.category.trim().toLowerCase()).toSet();

    // Find complementary target categories based on current cart
    final Set<String> targetComplementaryCats = {};
    for (final cat in cartCategories) {
      for (final entry in _complementaryCategories.entries) {
        if (cat.contains(entry.key)) {
          targetComplementaryCats.addAll(entry.value);
        }
      }
    }

    final List<MapEntry<ProductModel, double>> candidates = [];

    for (final product in allProducts) {
      final pNameLower = product.name.trim().toLowerCase();
      final pCatLower = product.category.trim().toLowerCase();

      // Avoid recommending items already in cart or out of stock
      if (cartTitles.contains(pNameLower)) continue;
      if (!product.isActive || product.stock <= 0) continue;

      double score = 0.0;

      // Complementary category match (+6)
      if (targetComplementaryCats.any((tc) => pCatLower.contains(tc))) {
        score += 6.0;
      }

      // Breakfast / Everyday staple cross-pair match (+5)
      if (cartTitles.any((ct) => ct.contains('bread') || ct.contains('egg') || ct.contains('milk'))) {
        if (pNameLower.contains('butter') || pNameLower.contains('cheese') || pNameLower.contains('jam') || pNameLower.contains('cereal')) {
          score += 8.0;
        }
      }

      // Tea/Coffee -> Sugar/Milk/Biscuits
      if (cartTitles.any((ct) => ct.contains('tea') || ct.contains('coffee'))) {
        if (pNameLower.contains('sugar') || pNameLower.contains('milk') || pNameLower.contains('biscuit') || pNameLower.contains('cookie')) {
          score += 8.0;
        }
      }

      // General featured/popular bonus (+2)
      if (product.isFeatured) score += 2.0;

      if (score > 0) {
        candidates.add(MapEntry(product, score));
      }
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final results = candidates.map((e) => e.key).toList();

    // Fill with popular products if needed
    if (results.length < limit) {
      final popular = await getPopularProducts(limit: limit, availablePool: allProducts);
      for (final p in popular) {
        if (!cartTitles.contains(p.name.toLowerCase()) && !results.any((r) => r.id == p.id)) {
          results.add(p);
        }
        if (results.length >= limit) break;
      }
    }

    return results.take(limit).toList();
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// 4. POST-PURCHASE CROSS-SELL ("Customers Also Buy")
  /// ═════════════════════════════════════════════════════════════════════════
  Future<List<ProductModel>> getPostPurchaseRecommendations({
    required List<OrderItemModel> purchasedItems,
    int limit = 6,
    List<ProductModel>? availablePool,
  }) async {
    final allProducts = availablePool ?? await _getAllAvailableProducts();
    final purchasedNames = purchasedItems.map((i) => i.productName.trim().toLowerCase()).toSet();

    final List<MapEntry<ProductModel, double>> candidates = [];

    for (final product in allProducts) {
      final pNameLower = product.name.trim().toLowerCase();

      if (purchasedNames.contains(pNameLower)) continue;
      if (!product.isActive || product.stock <= 0) continue;

      double score = 0.0;

      for (final purchased in purchasedItems) {
        final purName = purchased.productName.toLowerCase();
        if (_hasKeywordOverlap(purName, pNameLower)) {
          score += 4.0;
        }
      }

      if (product.isFeatured) score += 3.0;
      if (product.originalPrice != null && product.originalPrice! > product.price) score += 2.0;

      candidates.add(MapEntry(product, score));
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final results = candidates.map((e) => e.key).toList();

    if (results.length < limit) {
      final popular = await getPopularProducts(limit: limit, availablePool: allProducts);
      for (final p in popular) {
        if (!purchasedNames.contains(p.name.toLowerCase()) && !results.any((r) => r.id == p.id)) {
          results.add(p);
        }
        if (results.length >= limit) break;
      }
    }

    return results.take(limit).toList();
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// 5. POPULAR / TRENDING FALLBACK ("Popular Products")
  /// ═════════════════════════════════════════════════════════════════════════
  Future<List<ProductModel>> getPopularProducts({
    int limit = 8,
    List<ProductModel>? availablePool,
  }) async {
    final pool = availablePool ?? await _getAllAvailableProducts();

    if (pool.isEmpty) {
      return ProductRepository.fallbackProducts.take(limit).toList();
    }

    final sorted = List<ProductModel>.from(pool.where((p) => p.isActive && p.stock > 0))
      ..sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.stock.compareTo(a.stock);
      });

    return sorted.take(limit).toList();
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// HELPER METHODS
  /// ═════════════════════════════════════════════════════════════════════════

  Future<List<ProductModel>> _getAllAvailableProducts() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final snapshot = await _firestore
            .collection('products')
            .limit(100)
            .get()
            .timeout(const Duration(seconds: 3));

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .where((p) => p.isActive && !p.isExpired)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[RecommendationService] Firestore fetch products error: $e');
    }
    return ProductRepository.fallbackProducts;
  }

  Future<List<UserOrderModel>> _fetchUserOrders(String userId) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final snap = await _firestore
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .limit(20)
            .get()
            .timeout(const Duration(seconds: 3));

        return snap.docs.map((doc) => UserOrderModel.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('[RecommendationService] Fetch orders error: $e');
    }
    return [];
  }

  bool _isProductSimilar(String sourceName, String candidateName, String candidateCat) {
    if (sourceName == candidateName) return false;
    return _hasKeywordOverlap(sourceName, candidateName);
  }

  bool _hasKeywordOverlap(String str1, String str2) {
    final words1 = str1.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final words2 = str2.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    return words1.intersection(words2).isNotEmpty;
  }
}
