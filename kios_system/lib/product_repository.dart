import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class KioskProductRepository {
  static final KioskProductRepository instance = KioskProductRepository._();

  KioskProductRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _firestore.collection('products');

  /// Streams real-time list of active products from Firestore
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();
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
