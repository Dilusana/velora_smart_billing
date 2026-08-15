import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'order_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ---------------------------------------------------------------------------
// All orders — real-time stream
// ---------------------------------------------------------------------------

final firestoreOrdersProvider =
    StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchOrders();
});

// ---------------------------------------------------------------------------
// Single order — real-time stream (family)
// ---------------------------------------------------------------------------

final orderDetailProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});
