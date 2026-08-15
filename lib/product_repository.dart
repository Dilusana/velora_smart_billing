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
  }

  /// Checks if a product matches a target category (supports name, ID, or substring matching)
  bool productMatchesCategory(ProductModel product, String categoryTitle) {
    if (categoryTitle.trim().isEmpty) return true;
    final catTarget = categoryTitle.trim().toLowerCase();
    final prodCat = product.category.trim().toLowerCase();

    if (prodCat == catTarget) return true;
    if (prodCat.contains(catTarget) || catTarget.contains(prodCat)) return true;

    // Handle common mappings e.g. "Vegetables & Fruits" <-> "vegetables", "veg", "fruits"
    if (catTarget.contains('veg') || catTarget.contains('fruit')) {
      if (prodCat.contains('veg') || prodCat.contains('fruit') || prodCat.contains('produce')) {
        return true;
      }
    }
    if (catTarget.contains('beverage') || catTarget.contains('drink')) {
      if (prodCat.contains('beverage') || prodCat.contains('drink')) {
        return true;
      }
    }
    if (catTarget.contains('grocery') || catTarget.contains('pantry')) {
      if (prodCat.contains('grocery') || prodCat.contains('pantry') || prodCat.contains('grain')) {
        return true;
      }
    }
    if (catTarget.contains('household') || catTarget.contains('clean')) {
      if (prodCat.contains('household') || prodCat.contains('clean')) {
        return true;
      }
    }
    if (catTarget.contains('chilled')) {
      if (prodCat.contains('chill') || prodCat.contains('dairy')) {
        return true;
      }
    }
    if (catTarget.contains('frozen')) {
      if (prodCat.contains('frozen') || prodCat.contains('ice')) {
        return true;
      }
    }

    return false;
  }
}
