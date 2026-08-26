import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? map['title'] ?? map['name'] ?? 'Item').toString(),
      price: map['price'] is num ? (map['price'] as num).toDouble() : 0.0,
      quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 1,
      total: map['total'] is num ? (map['total'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

class UserOrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status; // Processing, Confirmed, Out for Delivery, Delivered, Cancelled
  final String orderSource;
  final String deliveryAddress;
  final String deliveryType;
  final DateTime? createdAt;

  const UserOrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.deliveryFee = 0.0,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.orderSource,
    this.deliveryAddress = '',
    this.deliveryType = 'delivery',
    this.createdAt,
  });

  factory UserOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((i) => OrderItemModel.fromMap(i as Map<String, dynamic>))
        .toList();

    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    final String delType = (data['deliveryType'] ?? data['deliverytype'] ?? (data['deliveryFee'] != null && parseDouble(data['deliveryFee']) > 0 ? 'delivery' : 'pickup')).toString();

    return UserOrderModel(
      id: doc.id,
      customerId: (data['customerId'] ?? 'cust_user').toString(),
      customerName: (data['customerName'] ?? 'Customer').toString(),
      items: itemsList,
      subtotal: parseDouble(data['subtotal']),
      discount: parseDouble(data['discount']),
      deliveryFee: parseDouble(data['deliveryFee']),
      total: parseDouble(data['total']),
      paymentMethod: (data['paymentmethod'] ?? data['paymentMethod'] ?? 'Card').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Paid').toString(),
      status: (data['status'] ?? 'Processing').toString(),
      orderSource: (data['ordersource'] ?? 'UserApp').toString(),
      deliveryAddress: (data['deliveryAddress'] ?? 'Home Address').toString(),
      deliveryType: delType,
      createdAt: created,
    );
  }
}
