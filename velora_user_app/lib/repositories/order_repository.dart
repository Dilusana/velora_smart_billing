import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/cart_service.dart';

class OrderRepository {
  static final OrderRepository instance = OrderRepository._();

  OrderRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _paymentsRef => _firestore.collection('payments');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _customersRef => _firestore.collection('customers');

  /// Submits order to Firestore:
  /// 1. Creates order document in `orders` collection
  /// 2. Creates payment document in `payments` collection
  /// 3. Atomically decrements product stock in `products` collection
  /// 4. Updates customer order count and total spend in `customers` collection
  /// 5. Clears local SQLite cart
  Future<String> submitOrder({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double deliveryFee,
    required double total,
    required String paymentMethod,
    required String customerId,
    required String customerName,
    required String deliveryAddress,
    String deliveryType = 'delivery',
    String? phone,
  }) async {
    final String orderDocId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final String cId = customerId.trim().isNotEmpty ? customerId.trim() : 'cust_user_app';
    final String cName = customerName.trim().isNotEmpty ? customerName.trim() : 'Valued Customer';
    final String address = deliveryAddress.trim().isNotEmpty ? deliveryAddress.trim() : 'Default Address';

    final List<Map<String, dynamic>> orderItems = items.map((item) {
      final double price = item.price;
      final double lineTotal = price * item.quantity;
      final String pId = item.productId.isNotEmpty
          ? item.productId
          : 'prod_${item.title.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

      return {
        'productId': pId,
        'productName': item.title,
        'price': price,
        'quantity': item.quantity,
        'total': lineTotal,
      };
    }).toList();

    final Map<String, dynamic> orderData = {
      'customerId': cId,
      'customerName': cName,
      'customerPhone': phone ?? '',
      'users': cName,
      'items': orderItems,
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentmethod': paymentMethod,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'Paid',
      'status': 'Processing',
      'ordersource': 'UserApp',
      'deliveryAddress': address,
      'deliveryType': deliveryType,
      'deliverytype': deliveryType,
      'branch': 'Main Branch',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final WriteBatch batch = _firestore.batch();

    // 1. Order write
    final DocumentReference orderRef = _ordersRef.doc(orderDocId);
    batch.set(orderRef, orderData);

    // 2. Payment write
    final String paymentDocId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final DocumentReference paymentRef = _paymentsRef.doc(paymentDocId);
    batch.set(paymentRef, {
      'id': paymentDocId,
      'paymentId': paymentDocId,
      'transactionId': 'tx_${DateTime.now().millisecondsSinceEpoch}',
      'orderId': orderDocId,
      'customerId': cId,
      'customerName': cName,
      'amount': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'Paid',
      'refundStatus': 'Not Refunded',
      'processedBy': 'UserApp',
      'paymentDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Atomically decrement stock in products collection
    for (final itemMap in orderItems) {
      final String pId = itemMap['productId'] as String;
      final int qty = itemMap['quantity'] as int;
      if (pId.isNotEmpty) {
        final DocumentReference pRef = _productsRef.doc(pId);
        batch.set(
          pRef,
          {
            'stock': FieldValue.increment(-qty),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    // 4. Update customer stats
    final DocumentReference custRef = _customersRef.doc(cId);
    batch.set(
      custRef,
      {
        'id': cId,
        'name': cName,
        'totalOrders': FieldValue.increment(1),
        'totalSpend': FieldValue.increment(total),
        'lastOrderDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Commit batch transaction
    await batch.commit();

    // 5. Clear cart
    await CartService.instance.clearCart();

    return orderDocId;
  }

  /// Streams list of orders for customer
  Stream<List<UserOrderModel>> getCustomerOrdersStream(String customerId) {
    final String cId = customerId.isNotEmpty ? customerId : 'cust_user_app';
    return _ordersRef
        .where('customerId', isEqualTo: cId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => UserOrderModel.fromFirestore(doc)).toList();
      orders.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return orders;
    }).handleError((error) {
      return <UserOrderModel>[];
    });
  }

  /// Streams a single order by ID for live order tracking
  Stream<UserOrderModel?> getOrderByIdStream(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserOrderModel.fromFirestore(doc);
    }).handleError((_) => null);
  }
}
