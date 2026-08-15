import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _orders => _db.collection('orders');

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Real-time stream of a single order by ID.
  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return OrderModel.fromMap({...data, 'id': doc.id});
    });
  }

  /// Real-time stream of all orders, newest first.
  Stream<List<OrderModel>> watchOrders() {
    return _orders.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return OrderModel.fromMap({...data, 'id': doc.id});
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// One-time fetch of a single order.
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap({...data, 'id': doc.id});
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Create a new order in Firestore.
  Future<String> createOrder(OrderModel order) async {
    final ref = _orders.doc();
    await ref.set(_toFirestore(order));
    return ref.id;
  }

  /// Update the status of an existing order.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _orders.doc(orderId).update({'status': newStatus});
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toFirestore(OrderModel order) {
    return {
      'customerId': order.customerId,
      'customerName': order.customerName,
      'items': order.items.map((x) => x.toMap()).toList(),
      'total': order.total,
      'paymentMethod': order.paymentMethod,
      'status': order.status,
      'branch': order.branch,
      'createdAt': order.createdAt.toIso8601String(),
    };
  }
}
