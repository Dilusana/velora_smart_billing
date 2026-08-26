import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_order_model.dart';

class DeliveryTrackingService {
  static final DeliveryTrackingService instance = DeliveryTrackingService._();
  DeliveryTrackingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  /// Get real-time stream of an order snapshot by orderId
  Stream<DeliveryOrderModel?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return DeliveryOrderModel.fromFirestore(doc);
      }
      return null;
    }).handleError((error) {
      debugPrint('Error streaming order $orderId: $error');
      return null;
    });
  }

  /// Get single order snapshot by orderId
  Future<DeliveryOrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        return DeliveryOrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order $orderId: $e');
      return null;
    }
  }

  /// Create a sample delivery order if none exists for testing
  Future<void> createOrSeedSampleOrder(DeliveryOrderModel order) async {
    try {
      await _ordersRef.doc(order.orderId).set(order.toMap(), SetOptions(merge: true));
      debugPrint('Sample order ${order.orderId} seeded successfully.');
    } catch (e) {
      debugPrint('Error seeding sample order: $e');
    }
  }
}
