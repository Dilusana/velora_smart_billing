import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class PromotionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _promotions => _db.collection('Promotion');

  /// Real-time stream of all promotions from Firestore
  Stream<List<PromotionModel>> getPromotions() {
    return _promotions.snapshots().asyncMap((snap) async {
      var docs = snap.docs;
      if (docs.isEmpty) {
        try {
          final snapLower = await _db.collection('promotions').get();
          if (snapLower.docs.isNotEmpty) {
            docs = snapLower.docs;
          }
        } catch (_) {}
      }
      return docs.map((doc) {
        return PromotionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    });
  }

  /// Create a new promotion in Firestore
  Future<void> addPromotion(PromotionModel promo) async {
    final docRef = promo.id.isNotEmpty && !promo.id.startsWith('promo-') && !promo.id.startsWith('mock-')
        ? _promotions.doc(promo.id)
        : _promotions.doc();

    final data = promo.copyWith(id: docRef.id).toMap();
    await docRef.set(data);

    try {
      await _db.collection('promotions').doc(docRef.id).set(data);
    } catch (_) {}
  }

  /// Update an existing promotion document
  Future<void> updatePromotion(PromotionModel promo) async {
    final data = promo.toMap();
    await _promotions.doc(promo.id).set(data, SetOptions(merge: true));
    try {
      await _db.collection('promotions').doc(promo.id).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Toggle active / inactive status of a promotion
  Future<void> toggleStatus(String id, bool isActive) async {
    final statusStr = isActive ? 'active' : 'inactive';
    await _promotions.doc(id).set({'status': statusStr}, SetOptions(merge: true));
    try {
      await _db.collection('promotions').doc(id).set({'status': statusStr}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Delete a promotion document from Firestore
  Future<void> deletePromotion(String id) async {
    await _promotions.doc(id).delete();
    try {
      await _db.collection('promotions').doc(id).delete();
    } catch (_) {}
  }
}
