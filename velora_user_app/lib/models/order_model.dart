import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;
  final bool isPicked;
  final String imageUrl;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.isPicked = false,
    this.imageUrl = '',
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? map['title'] ?? map['name'] ?? 'Item').toString(),
      price: map['price'] is num ? (map['price'] as num).toDouble() : 0.0,
      quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 1,
      total: map['total'] is num ? (map['total'] as num).toDouble() : 0.0,
      isPicked: map['isPicked'] == true,
      imageUrl: (map['imageUrl'] ?? map['image'] ?? map['imagePath'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
      'isPicked': isPicked,
      'imageUrl': imageUrl,
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
  final String driverName;
  final String driverPhone;
  final String employeeName;
  final String branch;
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
    this.driverName = '',
    this.driverPhone = '',
    this.employeeName = '',
    this.branch = 'Main Branch',
    this.createdAt,
  });

  int get totalItemsCount => items.fold(0, (acc, item) => acc + item.quantity);
  int get pickedItemsCount => items.fold(0, (acc, item) => acc + (item.isPicked ? item.quantity : 0));
  bool get isAllPicked => totalItemsCount > 0 && pickedItemsCount == totalItemsCount;
  double get pickingProgress => totalItemsCount > 0 ? (pickedItemsCount / totalItemsCount) : 0.0;

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
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']);
    }

    final String delType = (data['deliveryType'] ?? data['deliverytype'] ?? (data['deliveryFee'] != null && parseDouble(data['deliveryFee']) > 0 ? 'delivery' : (data['deliveryAddress']?.toString().toLowerCase().contains('pickup') == true ? 'pickup' : 'delivery'))).toString();

    final String dName = (data['driverName'] ?? data['driver'] ?? data['courierName'] ?? data['assignedDriver'] ?? '').toString();
    final String dPhone = (data['driverPhone'] ?? data['courierPhone'] ?? data['driver_phone'] ?? '').toString();
    final String empName = (data['employeeName'] ?? data['assignedEmployee'] ?? data['pickedBy'] ?? data['processedBy'] ?? data['employee'] ?? data['userName'] ?? '').toString();
    final String branchName = (data['branch'] ?? data['branchName'] ?? 'Main Store').toString();

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
      driverName: dName,
      driverPhone: dPhone,
      employeeName: empName,
      branch: branchName,
      createdAt: created,
    );
  }
}
