import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class KioskProductRepository {
  static final KioskProductRepository instance = KioskProductRepository._();

  KioskProductRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _firestore.collection('products');

  /// Fallback products list when Firebase collection is empty or offline
  static const List<ProductModel> fallbackProducts = [
    // Vegetables & Fruits
    ProductModel(
      id: 'fallback_vf_1',
      name: 'Organic Fuji Apples',
      description: 'Fresh, crisp organic fuji apples imported fresh daily.',
      category: 'Vegetables & Fruits',
      price: 360.0,
      stock: 120,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_vf_2',
      name: 'Fresh Banana Bundle',
      description: 'Sweet and ripe Cavendish bananas (1 kg).',
      category: 'Vegetables & Fruits',
      price: 240.0,
      stock: 85,
      imageUrl: '',
      status: 'active',
    ),

    // Grocery
    ProductModel(
      id: 'fallback_gr_1',
      name: 'Basmati Rice 5kg',
      description: 'Premium long-grain aromatic basmati rice.',
      category: 'Grocery',
      price: 1480.0,
      stock: 45,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_gr_2',
      name: 'Extra Virgin Olive Oil 1L',
      description: 'Cold-pressed extra virgin olive oil from Italy.',
      category: 'Grocery',
      price: 2250.0,
      stock: 30,
      imageUrl: '',
      status: 'active',
    ),

    // Beverages
    ProductModel(
      id: 'fallback_bv_1',
      name: 'Sparkling Water 6-Pack',
      description: 'Refreshing sparkling mineral water (6 x 500ml).',
      category: 'Beverages',
      price: 300.0,
      stock: 210,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_bv_2',
      name: 'Fresh Orange Juice 1L',
      description: '100% pure squeezed orange juice with no added sugar.',
      category: 'Beverages',
      price: 450.0,
      stock: 60,
      imageUrl: '',
      status: 'active',
    ),

    // Household
    ProductModel(
      id: 'fallback_hh_1',
      name: 'All-Purpose Cleaner 1L',
      description: 'Multipurpose floor and surface disinfectant cleaner.',
      category: 'Household',
      price: 650.0,
      stock: 80,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_hh_2',
      name: 'Dishwashing Liquid 500ml',
      description: 'Tough on grease lemon dishwashing liquid.',
      category: 'Household',
      price: 380.0,
      stock: 95,
      imageUrl: '',
      status: 'active',
    ),

    // Chilled Foods
    ProductModel(
      id: 'fallback_cf_1',
      name: 'Fresh Whole Milk 1L',
      description: 'Pasteurized fresh farm whole milk.',
      category: 'Chilled Foods',
      price: 320.0,
      stock: 75,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_cf_2',
      name: 'Cheddar Cheese Block 250g',
      description: 'Rich and creamy sharp cheddar cheese.',
      category: 'Chilled Foods',
      price: 750.0,
      stock: 40,
      imageUrl: '',
      status: 'active',
    ),

    // Frozen Foods
    ProductModel(
      id: 'fallback_ff_1',
      name: 'Vanilla Ice Cream 1L',
      description: 'Rich vanilla bean dairy ice cream tub.',
      category: 'Frozen Foods',
      price: 890.0,
      stock: 50,
      imageUrl: '',
      status: 'active',
    ),
    ProductModel(
      id: 'fallback_ff_2',
      name: 'Frozen French Fries 1kg',
      description: 'Crispy oven-baked cut potato fries.',
      category: 'Frozen Foods',
      price: 950.0,
      stock: 65,
      imageUrl: '',
      status: 'active',
    ),
  ];

  /// Streams real-time list of active products from Firestore with fallback
  Stream<List<ProductModel>> getProductsStream() {
    try {
      return _productsRef.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .where((p) => p.isActive)
            .toList();
        if (list.isEmpty) {
          return fallbackProducts;
        }
        return list;
      }).handleError((error) {
        // If Firestore is permission-denied, unconfigured, or offline, return fallbacks
        return fallbackProducts;
      });
    } catch (_) {
      return Stream.value(fallbackProducts);
    }
  }

  /// Checks if a product matches a target category (supports name, ID, or token/singular/plural matching)
  bool productMatchesCategory(
    ProductModel product,
    String categoryTitle, {
    String categoryId = '',
  }) {
    final catTarget = categoryTitle.trim().toLowerCase();
    final catIdTarget = categoryId.trim().toLowerCase();

    if (catTarget.isEmpty && catIdTarget.isEmpty) return true;

    final prodCat = product.category.trim().toLowerCase();
    final prodCatId = product.categoryId.trim().toLowerCase();

    // 1. Direct equality check on category ID or category name
    if (catIdTarget.isNotEmpty) {
      if (prodCatId == catIdTarget || prodCat == catIdTarget) return true;
    }
    if (catTarget.isNotEmpty) {
      if (prodCat == catTarget || prodCatId == catTarget) return true;
    }

    // 2. Substring check
    if (catTarget.isNotEmpty && prodCat.isNotEmpty) {
      if (prodCat.contains(catTarget) || catTarget.contains(prodCat)) return true;
    }

    // 3. Word stem / token matching (handles singular/plural e.g. "vegetable" vs "vegetables")
    final targetWords = _extractWords(catTarget);
    final prodWords = _extractWords(prodCat);

    for (final tw in targetWords) {
      for (final pw in prodWords) {
        if (_wordsMatch(tw, pw)) return true;
      }
    }

    // Also check product name or description against target category words if category field in product is missing or generic
    if (prodCat.isEmpty || prodCat == 'general' || prodCat == 'uncategorized') {
      final nameWords = _extractWords(product.name.toLowerCase());
      for (final tw in targetWords) {
        for (final nw in nameWords) {
          if (_wordsMatch(tw, nw)) return true;
        }
      }
    }

    // 4. Fallback category group matching
    if (catTarget.contains('veg') || catTarget.contains('fruit')) {
      if (prodCat.contains('veg') || prodCat.contains('fruit') || prodCat.contains('produce')) return true;
    }
    if (catTarget.contains('beverag') || catTarget.contains('drink')) {
      if (prodCat.contains('beverag') || prodCat.contains('drink')) return true;
    }
    if (catTarget.contains('grocer') || catTarget.contains('pantry')) {
      if (prodCat.contains('grocer') || prodCat.contains('pantry') || prodCat.contains('grain')) return true;
    }
    if (catTarget.contains('house') || catTarget.contains('clean')) {
      if (prodCat.contains('house') || prodCat.contains('clean')) return true;
    }
    if (catTarget.contains('chill') || catTarget.contains('dair')) {
      if (prodCat.contains('chill') || prodCat.contains('dair')) return true;
    }
    if (catTarget.contains('frozen') || catTarget.contains('ice')) {
      if (prodCat.contains('frozen') || prodCat.contains('ice')) return true;
    }

    return false;
  }

  List<String> _extractWords(String text) {
    final clean = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return clean
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && w != 'and' && w != 'for')
        .toList();
  }

  bool _wordsMatch(String w1, String w2) {
    if (w1 == w2) return true;
    if (w1.length >= 4 && w2.length >= 4) {
      final stem1 = w1.replaceAll(RegExp(r'(es|s)$'), '');
      final stem2 = w2.replaceAll(RegExp(r'(es|s)$'), '');
      if (stem1 == stem2) return true;
      if (w1.startsWith(stem2) || w2.startsWith(stem1)) return true;
    }
    return false;
  }
}
