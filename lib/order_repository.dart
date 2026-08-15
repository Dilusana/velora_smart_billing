import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';
import 'cart_database.dart';

class KioskOrderRepository {
  static final KioskOrderRepository instance = KioskOrderRepository._();

  KioskOrderRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _paymentsRef => _firestore.collection('payments');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _customersRef => _firestore.collection('customers');

  /// Completes checkout:
  /// 1. Creates document in `orders/{orderDocId}` matching exact specification schema.
  /// 2. Creates document in `payments/{paymentDocId}` for transaction logging.
  /// 3. Atomically decrements product stock in `products/{productId}` using `FieldValue.increment(-quantity)`.
  /// 4. Updates customer order count and total spend in `customers/{customerId}` if customer details exist.
  /// 5. Clears SQLite cart database.
  Future<String> submitOrder({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMethod,
    String? customerId,
    String? customerName,
    String? userName,
    String? branchName,
  }) async {
    final String orderDocId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final String cId = (customerId != null && customerId.trim().isNotEmpty)
        ? customerId.trim()
        : 'cust_kiosk';
    final String cName = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : 'Kiosk Customer';
    final String user = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim()
        : 'Kiosk User';
    final String branch = (branchName != null && branchName.trim().isNotEmpty)
        ? branchName.trim()
        : 'Main Branch';

    // Format items array according to specification
    final List<Map<String, dynamic>> orderItems = items.map((item) {
      final double price = item.price > 0 ? item.price : (subtotal / (items.isEmpty ? 1 : items.length));
      final double lineTotal = price * item.quantity;
      final String pId = item.productId.isNotEmpty ? item.productId : 'prod_${item.title.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

      return {
        'productId': pId,
        'productName': item.title,
        'price': price,
        'quantity': item.quantity,
        'total': lineTotal,
      };
    }).toList();

    // Normalize payment method string (e.g. "card", "cash", "qr", "wallet")
    final String pMethodClean = _normalizePaymentMethod(paymentMethod);

    final Map<String, dynamic> orderData = {
      'customerId': cId,
      'customerName': cName,
      'users': user,
      'items': orderItems,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentmethod': pMethodClean,
      'paymentMethod': paymentMethod, // Dual field support for Admin compatibility
      'paymentStatus': 'paid',
      'status': 'Processing',
      'ordersource': 'Kiosk',
      'branch': branch,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Use WriteBatch or Transaction for atomic creation & stock deduction
    final WriteBatch batch = _firestore.batch();

    // 1. Write order
    final DocumentReference orderRef = _ordersRef.doc(orderDocId);
    batch.set(orderRef, orderData);

    // 2. Write payment
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
      'paymentStatus': 'paid',
      'refundStatus': 'Not Refunded',
      'processedBy': user,
      'paymentDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Atomically decrement stock in Firestore products collection
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

    // 4. Update customer stats if customerId is provided
    if (cId != 'cust_kiosk') {
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
    }

    // Commit batch transaction
    await batch.commit();

    // 5. Clear SQLite cart
    await CartDatabase.instance.clearCart();

    return orderDocId;
  }

  String _normalizePaymentMethod(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('card') || lower.contains('credit') || lower.contains('debit')) {
      return 'card';
    }
    if (lower.contains('cash')) {
      return 'cash';
    }
    if (lower.contains('qr')) {
      return 'qr';
    }
    if (lower.contains('wallet') || lower.contains('apple') || lower.contains('google')) {
      return 'digitalWallet';
    }
    return method;
  }
}
