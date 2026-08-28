import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _products =>
      _firestore.collection('products');

  /// Add Product
  Future<void> addProduct(ProductModel product) async {
    final data = _toFirestore(product);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.id).set(data);
  }

  /// Update Product
  Future<void> updateProduct(ProductModel product) async {
    final data = _toFirestore(product);
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.id).update(data);
  }

  /// Delete Product
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  /// Get All Products (real-time stream)
  Stream<List<ProductModel>> getProducts() {
    return _products.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => _fromFirestore(doc))
          .toList(),
    );
  }

  /// Get Single Product
  Future<ProductModel?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  // ---------- Private helpers ----------

  DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  /// Converts a Firestore [DocumentSnapshot] to a [ProductModel].
  ProductModel _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return ProductModel(
        id: doc.id,
        name: '',
        sku: '',
        category: '',
        price: 0.0,
        cost: 0.0,
        stock: 0,
        unit: '',
        status: 'inactive',
        imageUrl: '',
        description: '',
      );
    }
    return ProductModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      sku: data['sku']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ??
          double.tryParse(data['price']?.toString() ?? '') ??
          0.0,
      cost: (data['cost'] as num?)?.toDouble() ??
          double.tryParse(data['cost']?.toString() ?? '') ??
          0.0,
      stock: (data['stock'] as num?)?.toInt() ??
          int.tryParse(data['stock']?.toString() ?? '') ??
          0,
      unit: data['unit']?.toString() ?? '',
      status: data['status']?.toString() ?? 'active',
      imageUrl: data['imageUrl']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      expiryDate: _parseTimestamp(data['expiryDate'] ?? data['expiry_date'] ?? data['expiry'] ?? data['expirationDate'] ?? data['expDate']),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Converts a [ProductModel] to a Firestore-compatible map.
  Map<String, dynamic> _toFirestore(ProductModel product) {
    return {
      'name': product.name,
      'sku': product.sku,
      'category': product.category,
      'price': product.price,
      'cost': product.cost,
      'stock': product.stock,
      'unit': product.unit,
      'status': product.status,
      'imageUrl': product.imageUrl,
      'description': product.description,
      'expiryDate': product.expiryDate != null ? Timestamp.fromDate(product.expiryDate!) : null,
    };
  }

  /// Batch delete multiple products by ID
  Future<void> batchDeleteProducts(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_products.doc(id));
    }
    await batch.commit();
  }
}