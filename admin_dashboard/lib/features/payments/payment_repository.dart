import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class PaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _paymentRef => _db.collection('payment');
  CollectionReference get _paymentsRef => _db.collection('payments');

  /// Watch real-time stream of all payments
  Stream<List<PaymentModel>> watchPayments() {
    return _paymentRef.snapshots().asyncMap((snap) async {
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PaymentModel.fromMap(data, docId: doc.id);
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      // Fallback to 'payments' collection if 'payment' collection is empty
      final fallbackSnap = await _paymentsRef.get();
      final list = fallbackSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PaymentModel.fromMap(data, docId: doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Get single payment by ID
  Future<PaymentModel?> getPayment(String id) async {
    var doc = await _paymentRef.doc(id).get();
    if (!doc.exists) {
      doc = await _paymentsRef.doc(id).get();
    }
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromMap(data, docId: doc.id);
  }

  /// Add new payment
  Future<String> addPayment(PaymentModel payment) async {
    final ref = _paymentRef.doc();
    await ref.set(payment.toMap());
    return ref.id;
  }

  /// Process refund on a payment
  Future<void> refundPayment(String id, {double? refundAmount}) async {
    final docRef = _paymentRef.doc(id);
    final doc = await docRef.get();
    final target = doc.exists ? docRef : _paymentsRef.doc(id);

    await target.update({
      'paymentStatus': 'refunded',
      'status': 'refunded',
      'refundStatus': 'Refunded',
      if (refundAmount != null) 'refundAmount': refundAmount,
    });
  }
}
