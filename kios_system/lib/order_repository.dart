import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';
import 'cart_database.dart';
import 'sms_service.dart';

class KioskOrderRepository {
  static final KioskOrderRepository instance = KioskOrderRepository._();

  KioskOrderRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _paymentsRef => _firestore.collection('payments');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _customersRef => _firestore.collection('customers');

  /// Saves or updates customer details into the Firestore `customers` collection.
  Future<void> saveOrUpdateCustomerProfile({
    required String phone,
    String? name,
    String? email,
    String? address,
  }) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;

    final String custId = cleanPhone.startsWith('cust_') ? cleanPhone : 'cust_$cleanPhone';
    final String cName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Customer ($cleanPhone)';
    final String cEmail = (email != null) ? email.trim() : '';
    final String cAddress = (address != null) ? address.trim() : '';

    final Map<String, dynamic> data = {
      'id': custId,
      'name': cName,
      'fullName': cName,
      'phone': cleanPhone,
      'customerPhone': cleanPhone,
      'status': 'active',
      'loyaltyTier': 'Bronze',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    };

    if (cEmail.isNotEmpty) {
      data['email'] = cEmail;
      data['gmail'] = cEmail;
    }
    if (cAddress.isNotEmpty) {
      data['address'] = cAddress;
    }

    try {
      await _customersRef.doc(custId).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Completes checkout:
  /// 1. Creates document in `orders/{orderDocId}` matching exact specification schema.
  /// 2. Creates document in `payments/{paymentDocId}` for transaction logging.
  /// 3. Atomically decrements product stock in `products/{productId}` using `FieldValue.increment(-quantity)`.
  /// 4. Creates or updates customer record with phone, name, email, and address in `customers/{customerId}`.
  /// 5. Clears SQLite cart database.
  Future<String> submitOrder({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMethod,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? userName,
    String? branchName,
    String deliveryType = 'pickup',
  }) async {
    final String orderDocId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final String cPhone = (customerPhone != null) ? customerPhone.trim() : '';
    final String cleanPhone = cPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    String cId = (customerId != null && customerId.trim().isNotEmpty)
        ? customerId.trim()
        : (cleanPhone.isNotEmpty ? 'cust_$cleanPhone' : 'cust_kiosk');

    final String cName = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : (cleanPhone.isNotEmpty ? 'Customer ($cleanPhone)' : 'Kiosk Customer');

    final String cEmail = (customerEmail != null) ? customerEmail.trim() : '';
    final String cAddress = (customerAddress != null) ? customerAddress.trim() : '';

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
      'orderId': orderDocId,
      'customerId': cId,
      'customerName': cName,
      'customerPhone': cPhone,
      'phone': cPhone,
      'customerEmail': cEmail,
      'email': cEmail,
      'customerAddress': cAddress,
      'address': cAddress,
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
      'deliveryType': deliveryType,
      'deliverytype': deliveryType,
      'branch': branch,
      'smsSent': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Use WriteBatch for atomic creation & stock deduction
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
      'customerPhone': cPhone,
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

    // 4. Create / Update customer document in Firestore with phone, name, email & address
    if (cId != 'cust_kiosk' || cleanPhone.isNotEmpty) {
      final String finalCustDocId = cId != 'cust_kiosk' ? cId : 'cust_$cleanPhone';
      final DocumentReference custRef = _customersRef.doc(finalCustDocId);

      final Map<String, dynamic> customerData = {
        'id': finalCustDocId,
        'name': cName,
        'fullName': cName,
        'phone': cleanPhone.isNotEmpty ? cleanPhone : cPhone,
        'customerPhone': cleanPhone.isNotEmpty ? cleanPhone : cPhone,
        'status': 'active',
        'loyaltyTier': 'Bronze',
        'loyaltyPoints': FieldValue.increment((total / 100).floor()),
        'totalOrders': FieldValue.increment(1),
        'totalSpend': FieldValue.increment(total),
        'lastOrderDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (cEmail.isNotEmpty) {
        customerData['email'] = cEmail;
        customerData['gmail'] = cEmail;
      }
      if (cAddress.isNotEmpty) {
        customerData['address'] = cAddress;
      }

      batch.set(custRef, customerData, SetOptions(merge: true));
    }

    // Commit batch transaction
    await batch.commit();

    // 5. Clear SQLite cart
    await CartDatabase.instance.clearCart();

    // 6. Trigger Text.lk SMS dispatch asynchronously (non-blocking)
    if (cPhone.isNotEmpty) {
      SmsService.instance.sendOrderSms(
        orderDocId: orderDocId,
        customerPhone: cPhone,
        totalAmount: total,
      );
    }

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
