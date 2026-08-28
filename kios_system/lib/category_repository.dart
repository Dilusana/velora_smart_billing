import 'package:cloud_firestore/cloud_firestore.dart';
import 'category.dart';

/// Repository for streaming and fetching category data from Firestore.
class KioskCategoryRepository {
  static final KioskCategoryRepository instance = KioskCategoryRepository._();

  KioskCategoryRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _categoriesRef => _firestore.collection('categories');

  /// Streams real-time list of active categories from Firestore with fallback to kCategories.
  Stream<List<CategoryItem>> getCategoriesStream() {
    try {
      return _categoriesRef.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => CategoryItem.fromFirestore(doc))
            .where((cat) => cat.isActive)
            .toList();

        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (list.isEmpty) {
          return kCategories;
        }
        return list;
      }).handleError((error) {
        // If Firestore is offline or unconfigured, fallback to default kCategories
        return kCategories;
      });
    } catch (_) {
      return Stream.value(kCategories);
    }
  }
}
