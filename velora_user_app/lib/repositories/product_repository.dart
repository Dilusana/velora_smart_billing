import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductRepository {
  static final ProductRepository instance = ProductRepository._();

  ProductRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _firestore.collection('products');

  /// Fallback products when Firestore is empty, unconfigured, or offline
  static const List<ProductModel> fallbackProducts = [
    ProductModel(
      id: 'fallback_vf_1',
      name: 'Organic Fuji Apples',
      description: 'Fresh, crisp organic fuji apples imported fresh daily.',
      category: 'Vegetables & Fruits',
      price: 360.0,
      originalPrice: 420.0,
      stock: 120,
      imageUrl: '',
      unit: '1 kg',
      status: 'active',
      isFeatured: true,
    ),
    ProductModel(
      id: 'fallback_vf_2',
      name: 'Fresh Banana Bundle',
      description: 'Sweet and ripe Cavendish bananas.',
      category: 'Vegetables & Fruits',
      price: 240.0,
      originalPrice: 280.0,
      stock: 85,
      imageUrl: '',
      unit: '1 kg',
      status: 'active',
      isFeatured: false,
    ),
    ProductModel(
      id: 'fallback_gr_1',
      name: 'Basmati Rice 5kg',
      description: 'Premium long-grain aromatic basmati rice.',
      category: 'Grocery',
      price: 1480.0,
      originalPrice: 1650.0,
      stock: 45,
      imageUrl: '',
      unit: '5 kg',
      status: 'active',
      isFeatured: true,
    ),
    ProductModel(
      id: 'fallback_gr_2',
      name: 'Extra Virgin Olive Oil 1L',
      description: 'Cold-pressed extra virgin olive oil from Italy.',
      category: 'Grocery',
      price: 2250.0,
      originalPrice: 2500.0,
      stock: 30,
      imageUrl: '',
      unit: '1 L',
      status: 'active',
      isFeatured: true,
    ),
    ProductModel(
      id: 'fallback_bv_1',
      name: 'Sparkling Water 6-Pack',
      description: 'Refreshing sparkling mineral water (6 x 500ml).',
      category: 'Beverages',
      price: 300.0,
      originalPrice: 350.0,
      stock: 210,
      imageUrl: '',
      unit: '6 x 500ml',
      status: 'active',
      isFeatured: false,
    ),
    ProductModel(
      id: 'fallback_bv_2',
      name: 'Fresh Orange Juice 1L',
      description: '100% pure squeezed orange juice with no added sugar.',
      category: 'Beverages',
      price: 450.0,
      originalPrice: 500.0,
      stock: 60,
      imageUrl: '',
      unit: '1 L',
      status: 'active',
      isFeatured: true,
    ),
    ProductModel(
      id: 'fallback_hh_1',
      name: 'All-Purpose Cleaner 1L',
      description: 'Multipurpose floor and surface disinfectant cleaner.',
      category: 'Household',
      price: 650.0,
      stock: 80,
      imageUrl: '',
      unit: '1 L',
      status: 'active',
      isFeatured: false,
    ),
    ProductModel(
      id: 'fallback_cf_1',
      name: 'Fresh Whole Milk 1L',
      description: 'Pasteurized fresh farm whole milk.',
      category: 'Chilled Foods',
      price: 320.0,
      stock: 75,
      imageUrl: '',
      unit: '1 L',
      status: 'active',
      isFeatured: true,
    ),
  ];

  /// Streams real-time active products from Firestore with fallback
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return fallbackProducts;
      }
      final list = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();
      if (list.isEmpty) {
        // If snapshot has docs but isActive filtered them all, include all parsed docs
        final allDocs = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
        return allDocs.isNotEmpty ? allDocs : fallbackProducts;
      }
      return list;
    }).handleError((error) {
      return fallbackProducts;
    });
  }

  /// Filters products by category (matching Category ID or Category Name)
  List<ProductModel> filterByCategory(
    List<ProductModel> products,
    String categoryNameOrId, {
    List<CategoryModel>? categories,
  }) {
    final rawTarget = categoryNameOrId.trim();
    if (rawTarget.isEmpty ||
        rawTarget.toLowerCase() == 'all' ||
        rawTarget.toLowerCase() == 'all categories') {
      return products;
    }

    final catTarget = rawTarget.replaceAll('\n', ' ').toLowerCase();

    // Look for matching CategoryModel if list provided
    CategoryModel? matchedCategory;
    if (categories != null && categories.isNotEmpty) {
      for (final cat in categories) {
        final cId = cat.id.trim().toLowerCase();
        final cTitle = cat.title.trim().replaceAll('\n', ' ').toLowerCase();
        if (cId == catTarget || cTitle == catTarget) {
          matchedCategory = cat;
          break;
        }
      }
    }

    final targetId = matchedCategory?.id.toLowerCase() ?? catTarget;
    final targetTitle = matchedCategory?.title.trim().replaceAll('\n', ' ').toLowerCase() ?? catTarget;

    final matches = products.where((p) {
      final pCat = p.category.trim().replaceAll('\n', ' ').toLowerCase();
      final pCatId = p.categoryId.trim().toLowerCase();

      // Check ID match
      if (pCatId.isNotEmpty && pCatId == targetId) return true;
      if (pCat.isNotEmpty && pCat == targetId) return true;

      // Check title/name match
      if (pCat == targetTitle || pCat.contains(targetTitle) || targetTitle.contains(pCat)) {
        return true;
      }

      // Group keyword fallbacks
      final checkStr = '$pCat $pCatId';
      if (targetTitle.contains('veg') || targetTitle.contains('fruit')) {
        return checkStr.contains('veg') || checkStr.contains('fruit') || checkStr.contains('produce') || checkStr.contains('fresh');
      }
      if (targetTitle.contains('beverag') || targetTitle.contains('drink') || targetTitle.contains('juice')) {
        return checkStr.contains('beverag') || checkStr.contains('drink') || checkStr.contains('juice') || checkStr.contains('water');
      }
      if (targetTitle.contains('grocer') || targetTitle.contains('pantry') || targetTitle.contains('grain')) {
        return checkStr.contains('grocer') || checkStr.contains('pantry') || checkStr.contains('grain') || checkStr.contains('food');
      }
      if (targetTitle.contains('house') || targetTitle.contains('clean')) {
        return checkStr.contains('house') || checkStr.contains('clean');
      }
      if (targetTitle.contains('chill') || targetTitle.contains('dair')) {
        return checkStr.contains('chill') || checkStr.contains('dair') || checkStr.contains('milk') || checkStr.contains('cheese');
      }
      if (targetTitle.contains('frozen') || targetTitle.contains('ice')) {
        return checkStr.contains('frozen') || checkStr.contains('ice');
      }

      return false;
    }).toList();

    return matches;
  }

  /// Searches products by query term
  List<ProductModel> searchProducts(List<ProductModel> products, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;

    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }
}
