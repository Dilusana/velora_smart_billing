import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _ordersCol = _db.collection('orders');

  /// Stream today's orders from Firestore in real-time
  /// Only returns orders where createdAt >= start of today (midnight)
  static Stream<List<OrderModel>> getOrdersStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayStartTimestamp = Timestamp.fromDate(todayStart);

    return _ordersCol
        .where('createdAt', isGreaterThanOrEqualTo: todayStartTimestamp)
        .snapshots()
        .map((snapshot) {
      final list = <OrderModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(OrderModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('Error parsing order doc ${doc.id}: $e');
        }
      }
      // Sort newest created first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      debugPrint('Error in getOrdersStream: $error');
      return <OrderModel>[];
    });
  }

  /// Stream all orders in real-time from Firestore for Order History
  static Stream<List<OrderModel>> getAllOrdersStream() {
    return _ordersCol.snapshots().map((snapshot) {
      final list = <OrderModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(OrderModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('Error parsing order doc ${doc.id}: $e');
        }
      }
      // Sort newest created first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      debugPrint('Error in getAllOrdersStream: $error');
      return <OrderModel>[];
    });
  }

  /// Stream all delivery orders in real-time from Firestore where deliveryType is 'delivery' (for Today)
  static Stream<List<OrderModel>> getDeliveryOrdersStream({bool todayOnly = true}) {
    return _ordersCol.snapshots().map((snapshot) {
      final list = <OrderModel>[];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      for (final doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc);
          if (order.isDelivery) {
            final isToday = order.createdAt.isAfter(todayStart) ||
                (order.createdAt.year == now.year &&
                    order.createdAt.month == now.month &&
                    order.createdAt.day == now.day);
            if (!todayOnly || isToday || order.normalizedStatus != 'COMPLETED') {
              list.add(order);
            }
          }
        } catch (e) {
          debugPrint('Error parsing delivery order doc ${doc.id}: $e');
        }
      }
      // Sort newest created first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      debugPrint('Error in getDeliveryOrdersStream: $error');
      return <OrderModel>[];
    });
  }

  /// Stream orders specifically assigned to a driver for today's date
  /// Stream orders specifically assigned to a driver for today's date
  /// Rule: Today's Orders = Only orders assigned to the logged-in driver for today's date.
  /// Delivery Queue = Orders waiting to be delivered (including status 'Completed', 'Assigned', 'Ready', etc.)
  static Stream<List<OrderModel>> getDriverTodayOrdersStream({
    required String driverId,
    DateTime? date,
  }) {
    final targetDate = date ?? DateTime.now();
    final todayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _ordersCol.snapshots().map((snapshot) {
      final list = <OrderModel>[];

      for (final doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc);
          // Check if order is delivery type
          if (!order.isDelivery) continue;

          // Check if assigned to this specific driver (or unassigned in hub)
          if (!order.isAssignedToDriver(driverId)) continue;

          final effectiveDate = order.assignedAt ?? order.createdAt;
          final isToday = (effectiveDate.isAfter(todayStart) && effectiveDate.isBefore(todayEnd)) ||
              (effectiveDate.year == targetDate.year &&
                  effectiveDate.month == targetDate.month &&
                  effectiveDate.day == targetDate.day);

          if (order.isDelivered) {
            // For Delivered Orders section, only show orders delivered today
            final delDate = order.deliveredAt ?? effectiveDate;
            final isDeliveredToday = (delDate.isAfter(todayStart) && delDate.isBefore(todayEnd)) ||
                (delDate.year == targetDate.year &&
                    delDate.month == targetDate.month &&
                    delDate.day == targetDate.day);
            if (isDeliveredToday) {
              list.add(order);
            }
          } else {
            // For active Delivery Queue (orders not delivered yet, including 'Completed', 'Assigned', 'Ready', 'Picking', 'Processing', 'New')
            // Include today's assigned/created orders
            if (isToday || order.normalizedStatus == 'COMPLETED' || order.normalizedStatus == 'ASSIGNED' || order.normalizedStatus == 'READY') {
              list.add(order);
            }
          }
        } catch (e) {
          debugPrint('Error parsing driver order doc ${doc.id}: $e');
        }
      }

      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      debugPrint('Error in getDriverTodayOrdersStream: $error');
      return <OrderModel>[];
    });
  }

  /// Stream a single order by doc ID or matching order ID
  static Stream<OrderModel?> getOrderByIdStream(String orderId) {
    if (orderId.isEmpty) return Stream.value(null);
    return _ordersCol.doc(orderId).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        try {
          return OrderModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing single order doc ${doc.id}: $e');
        }
      }
      // If not matching doc.id directly, try matching orderId / displayId in collection
      try {
        final query = await _ordersCol.get();
        for (var d in query.docs) {
          try {
            final order = OrderModel.fromFirestore(d);
            if (d.id == orderId || order.id == orderId || order.displayId.toLowerCase() == orderId.toLowerCase()) {
              return order;
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Error querying fallback orders: $e');
      }
      return null;
    }).handleError((_) => null);
  }

  /// Mark an order as Delivered in Firestore
  static Future<bool> markOrderDelivered(String docId, {String? driverId, String? driverName}) async {
    try {
      final updateMap = <String, dynamic>{
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (driverId != null && driverId.isNotEmpty) {
        updateMap['assignedDriverId'] = driverId;
        updateMap['driverId'] = driverId;
      }
      if (driverName != null && driverName.isNotEmpty) {
        updateMap['assignedDriverName'] = driverName;
        updateMap['driverName'] = driverName;
      }
      await _ordersCol.doc(docId).update(updateMap);
      return true;
    } catch (e) {
      debugPrint('Error marking order $docId as delivered: $e');
      return false;
    }
  }

  /// Update order status in Firestore
  static Future<bool> updateOrderStatus(String docId, String newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == 'Assigned') {
        updateData['assignedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus.toLowerCase() == 'delivered' || newStatus.toLowerCase() == 'completed') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await _ordersCol.doc(docId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating order status for $docId: $e');
      return false;
    }
  }

  /// Assign order to driver
  static Future<bool> assignOrderToDriver({
    required String docId,
    required String driverId,
    String? driverName,
  }) async {
    try {
      final updateMap = <String, dynamic>{
        'assignedDriverId': driverId,
        'driverId': driverId,
        'status': 'Assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (driverName != null && driverName.isNotEmpty) {
        updateMap['assignedDriverName'] = driverName;
        updateMap['driverName'] = driverName;
      }
      await _ordersCol.doc(docId).update(updateMap);
      return true;
    } catch (e) {
      debugPrint('Error assigning driver $driverId to order $docId: $e');
      return false;
    }
  }

  /// Toggle item picking state inside items array of order
  static Future<bool> toggleOrderItemPicked(String docId, int itemIndex, bool isPicked) async {
    try {
      final docSnap = await _ordersCol.doc(docId).get();
      if (!docSnap.exists) return false;

      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      if (itemIndex < 0 || itemIndex >= items.length) return false;

      items[itemIndex]['isPicked'] = isPicked;

      // Check if all items picked -> auto update status to Packing / Ready if appropriate
      final allPicked = items.every((i) => i['isPicked'] == true);
      String currentStatus = data['status'] as String? ?? 'Picking';
      if (allPicked && (currentStatus == 'Picking' || currentStatus == 'Processing' || currentStatus == 'Assigned')) {
        currentStatus = 'Ready';
      }

      await _ordersCol.doc(docId).update({
        'items': items,
        'status': currentStatus,
      });

      return true;
    } catch (e) {
      debugPrint('Error toggling item picked state for $docId: $e');
      return false;
    }
  }
}

