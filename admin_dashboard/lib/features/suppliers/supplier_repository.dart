import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class SupplierRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _suppliers => _db.collection('suppliers');

  /// Watch real-time stream of all suppliers
  Stream<List<SupplierModel>> watchSuppliers() {
    return _suppliers.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SupplierModel.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  /// Get single supplier by ID
  Future<SupplierModel?> getSupplier(String id) async {
    final doc = await _suppliers.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return SupplierModel.fromMap(data, docId: doc.id);
  }

  /// Add new supplier
  Future<String> addSupplier(SupplierModel supplier) async {
    final ref = _suppliers.doc();
    await ref.set(supplier.toMap());
    return ref.id;
  }

  /// Update supplier
  Future<void> updateSupplier(SupplierModel supplier) async {
    await _suppliers.doc(supplier.id).set(supplier.toMap(), SetOptions(merge: true));
  }

  /// Delete supplier
  Future<void> deleteSupplier(String id) async {
    await _suppliers.doc(id).delete();
  }
}
