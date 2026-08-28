import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion_model.dart';

class PromotionRepository {
  static final PromotionRepository instance = PromotionRepository._();

  PromotionRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _promotionsRef => _firestore.collection('Promotion');

  /// Streams active promotions from Firestore (checks both 'Promotion' and 'promotions' collection)
  Stream<List<PromotionModel>> getPromotionsStream() {
    return _promotionsRef.snapshots().asyncMap((snapshot) async {
      var docs = snapshot.docs;
      if (docs.isEmpty) {
        try {
          final snapLower = await _firestore.collection('promotions').get();
          if (snapLower.docs.isNotEmpty) {
            docs = snapLower.docs;
          }
        } catch (_) {}
      }

      final list = docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .where((promo) => promo.isActive)
          .toList();

      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }
}
