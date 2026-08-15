import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _categories => _firestore.collection('categories');

  Future<void> addCategory(CategoryModel category) async {
    final docRef = _categories.doc(); // auto-generated ID
    await docRef.set(_toFirestore(category));
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categories.doc(category.id).update(_toFirestore(category));
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  Stream<List<CategoryModel>> getCategories() {
    return _categories.orderBy('name').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => _fromFirestore(doc)).toList(),
        );
  }

  Future<CategoryModel?> getCategory(String id) async {
    final doc = await _categories.doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  CategoryModel _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      productCount: (data['productCount'] ?? 0).toInt(),
      revenueShare: (data['revenueShare'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> _toFirestore(CategoryModel category) {
    return {
      'name': category.name,
      'imageUrl': category.imageUrl,
      'productCount': category.productCount,
      'revenueShare': category.revenueShare,
      'description': category.description,
    };
  }
}
