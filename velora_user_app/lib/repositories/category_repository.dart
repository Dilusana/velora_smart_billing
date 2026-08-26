import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryRepository {
  static final CategoryRepository instance = CategoryRepository._();

  CategoryRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _categoriesRef => _firestore.collection('categories');

  static const List<CategoryModel> fallbackCategories = [
    CategoryModel(
      id: 'cat_vf',
      title: 'Veg & Fruits',
      imageAsset: 'assests/veg_fruits.png',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'cat_gr',
      title: 'Grocery',
      imageAsset: 'assests/grocery.png',
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'cat_hh',
      title: 'Household',
      imageAsset: 'assests/household.png',
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'cat_ff',
      title: 'Frozen',
      imageAsset: 'assests/frozenfoods.jpeg',
      sortOrder: 4,
    ),
    CategoryModel(
      id: 'cat_cf',
      title: 'Chilled',
      imageAsset: 'assests/chilledfood.png',
      sortOrder: 5,
    ),
    CategoryModel(
      id: 'cat_bv',
      title: 'Beverages',
      imageAsset: 'assests/beverages.png',
      sortOrder: 6,
    ),
  ];

  /// Streams real-time active categories from Firestore database collection/table
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _categoriesRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .where((cat) => cat.isActive)
          .toList();

      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (list.isEmpty) {
        return fallbackCategories;
      }
      return list;
    }).handleError((error) {
      return fallbackCategories;
    });
  }
}
