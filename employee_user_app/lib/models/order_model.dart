import 'package:cloud_firestore/cloud_firestore.dart';

String _parseString(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  return val.toString();
}

num _parseNum(dynamic val, [num fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val;
  if (val is String) return num.tryParse(val) ?? fallback;
  return fallback;
}

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  return DateTime.now();
}

class OrderItemModel {
  final String productId;
  final String productName;
  final num price;
  final int quantity;
  final num total;
  final bool isPicked;
  final String category;
  final String sku;
  final String aisle;
  final String imageUrl;
  final bool hasSub;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.isPicked = false,
    this.category = 'General',
    this.sku = '',
    this.aisle = 'Aisle A',
    this.imageUrl = '',
    this.hasSub = false,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final qty = _parseNum(map['quantity'], 1).toInt();
    final pr = _parseNum(map['price'], 0);
    final tot = _parseNum(map['total'], pr * qty);
    final pName = _parseString(map['productName'] ?? map['name'] ?? map['title'], 'Item');
    final pId = _parseString(map['productId'] ?? map['id'], '');
    final skuVal = _parseString(map['sku'], pId.isNotEmpty ? 'SKU: ${pId.takeLast(6)}' : 'SKU: N/A');

    return OrderItemModel(
      productId: pId,
      productName: pName,
      price: pr,
      quantity: qty,
      total: tot,
      isPicked: map['isPicked'] == true,
      category: _parseString(map['category'], _inferCategory(pName)),
      sku: skuVal,
      aisle: _parseString(map['aisle'], _inferAisle(pName)),
      imageUrl: _parseString(map['imageUrl']),
      hasSub: map['hasSub'] == true,
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
      'category': category,
      'sku': sku,
      'aisle': aisle,
      'imageUrl': imageUrl,
      'hasSub': hasSub,
    };
  }

  static String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ice cream') || lower.contains('fruit') || lower.contains('tomato') || lower.contains('veg') || lower.contains('kale') || lower.contains('apple') || lower.contains('berry')) {
      return 'Veg & Fruits';
    } else if (lower.contains('tech') || lower.contains('bundle') || lower.contains('phone') || lower.contains('headphone') || lower.contains('electronics')) {
      return 'Electronics';
    } else if (lower.contains('butter') || lower.contains('oats') || lower.contains('pantry') || lower.contains('milk') || lower.contains('bread')) {
      return 'Grocery';
    }
    return 'Retail';
  }

  static String _inferAisle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit') || lower.contains('tomato') || lower.contains('veg') || lower.contains('kale')) {
      return 'Aisle A';
    } else if (lower.contains('tech') || lower.contains('electronics')) {
      return 'Aisle B';
    } else if (lower.contains('grocery') || lower.contains('pantry') || lower.contains('butter') || lower.contains('oats')) {
      return 'Aisle C';
    }
    return 'Aisle D';
  }
}

extension StringExtension on String {
  String takeLast(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }
}

class OrderModel {
  final String id;
  final String branch;
  final DateTime createdAt;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final num deliveryFee;
  final String deliveryType;
  final num discount;
  final List<OrderItemModel> items;
  final String orderSource;
  final String paymentMethod;
  final String paymentStatus;
  final String status; // New, Processing, Assigned, Picking, Ready, Delivered, Completed
  final num subtotal;
  final num total;
  final String users;
  final String assignedEmployeeName;
  final String assignedDriverId;
  final String assignedDriverName;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;
  final String specialInstructions;

  OrderModel({
    required this.id,
    required this.branch,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryFee,
    this.deliveryType = 'delivery',
    required this.discount,
    required this.items,
    required this.orderSource,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.users,
    this.assignedEmployeeName = 'Rahul A.',
    this.assignedDriverId = '',
    this.assignedDriverName = '',
    this.assignedAt,
    this.deliveredAt,
    this.specialInstructions = '',
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final parsedCreated = _parseDateTime(data['createdAt']);
    final parsedAssigned = data['assignedAt'] != null
        ? _parseDateTime(data['assignedAt'])
        : (data['assignedDate'] != null ? _parseDateTime(data['assignedDate']) : null);
    final parsedDelivered = data['deliveredAt'] != null
        ? _parseDateTime(data['deliveredAt'])
        : (data['completedAt'] != null ? _parseDateTime(data['completedAt']) : null);

    final rawItems = data['items'];
    final List<OrderItemModel> itemList = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          try {
            itemList.add(OrderItemModel.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final pMethod = _parseString(data['paymentMethod'] ?? data['paymentmethod'], 'Card');
    final delAddr = _parseString(data['deliveryAddress'], 'Store Pickup');
    final delFee = _parseNum(data['deliveryFee'], 0);
    final delType = _parseString(data['deliveryType'] ?? data['deliverytype'], delFee > 0 ? 'delivery' : 'pickup');

    final driverIdVal = _parseString(
      data['assignedDriverId'] ?? data['driverId'] ?? data['assignedDriver'] ?? data['assignedEmployeeId'],
    );
    final driverNameVal = _parseString(
      data['assignedDriverName'] ?? data['driverName'],
    );

    return OrderModel(
      id: doc.id,
      branch: _parseString(data['branch'], 'Main Branch'),
      createdAt: parsedCreated,
      customerId: _parseString(data['customerId']),
      customerName: _parseString(data['customerName'] ?? data['users'], 'Customer'),
      customerPhone: _parseString(data['customerPhone']),
      deliveryAddress: delAddr,
      deliveryFee: delFee,
      deliveryType: delType,
      discount: _parseNum(data['discount'], 0),
      items: itemList,
      orderSource: _parseString(data['ordersource'], 'UserApp'),
      paymentMethod: pMethod,
      paymentStatus: _parseString(data['paymentStatus'], 'Paid'),
      status: _parseString(data['status'], 'New'),
      subtotal: _parseNum(data['subtotal'], 0),
      total: _parseNum(data['total'], 0),
      users: _parseString(data['users']),
      assignedEmployeeName: _parseString(data['assignedEmployeeName'], 'Rahul A.'),
      assignedDriverId: driverIdVal,
      assignedDriverName: driverNameVal,
      assignedAt: parsedAssigned,
      deliveredAt: parsedDelivered,
      specialInstructions: _parseString(data['specialInstructions']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branch': branch,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
      'deliveryType': deliveryType,
      'discount': discount,
      'items': items.map((i) => i.toMap()).toList(),
      'ordersource': orderSource,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'subtotal': subtotal,
      'total': total,
      'users': users,
      'assignedEmployeeName': assignedEmployeeName,
      if (assignedDriverId.isNotEmpty) 'assignedDriverId': assignedDriverId,
      if (assignedDriverName.isNotEmpty) 'assignedDriverName': assignedDriverName,
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      'specialInstructions': specialInstructions,
    };
  }

  // Delivery Check Getter
  bool get isDelivery {
    final type = deliveryType.trim().toLowerCase();
    if (type == 'delivery') return true;
    if (type == 'pickup') return false;
    return deliveryFee > 0 || (!deliveryAddress.toLowerCase().contains('pickup') && deliveryAddress.isNotEmpty);
  }

  // Display Helper Getters
  String get displayId {
    if (id.startsWith('order_')) {
      return 'ORD-${id.takeLast(4)}';
    } else if (id.length > 8) {
      return 'ORD-${id.substring(0, 4).toUpperCase()}';
    }
    return id.toUpperCase();
  }

  int get totalItemsCount {
    if (items.isEmpty) return 0;
    return items.fold(0, (acc, item) => acc + item.quantity);
  }

  int get pickedItemsCount {
    if (items.isEmpty) return 0;
    return items.fold(0, (acc, item) => acc + (item.isPicked ? item.quantity : 0));
  }

  double get progressPercentage {
    if (items.isEmpty) return 0.0;
    final totalQty = totalItemsCount;
    if (totalQty == 0) return 0.0;
    return pickedItemsCount / totalQty;
  }

  String get primaryCategory {
    if (items.isEmpty) return 'General';
    return items.first.category;
  }

  String get timeAgoFormatted {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get createdTimeFormatted {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get deliveredTimeFormatted {
    if (deliveredAt == null) return 'Today';
    final hour = deliveredAt!.hour % 12 == 0 ? 12 : deliveredAt!.hour % 12;
    final minute = deliveredAt!.minute.toString().padLeft(2, '0');
    final period = deliveredAt!.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Status Normalizer
  String get normalizedStatus {
    final s = status.trim().toLowerCase();
    if (s == 'new' || s == 'pending') return 'NEW';
    if (s == 'processing') return 'PROCESSING';
    if (s == 'assigned') return 'ASSIGNED';
    if (s == 'picking' || s == 'items picking' || s == 'in progress') return 'PICKING';
    if (s == 'packing') return 'PACKING';
    if (s == 'ready' || s == 'ready for pickup') return 'READY';
    if (s == 'out_for_delivery' || s == 'out for delivery' || s == 'on the way') return 'OUT FOR DELIVERY';
    if (s == 'delivered') return 'DELIVERED';
    if (s == 'completed') return 'COMPLETED';
    return s.toUpperCase();
  }

  /// Whether the order is delivered to the customer
  bool get isDelivered {
    return normalizedStatus == 'DELIVERED';
  }

  /// Check if the order is assigned to a specific driver ID
  bool isAssignedToDriver(String driverId) {
    if (driverId.isEmpty) return true;
    final target = driverId.trim().toLowerCase();
    final currentAssigned = assignedDriverId.trim().toLowerCase();
    if (currentAssigned.isNotEmpty) {
      return currentAssigned == target ||
          assignedDriverName.trim().toLowerCase() == target ||
          assignedEmployeeName.trim().toLowerCase() == target;
    }
    // If no driver is explicitly assigned yet, allow current logged-in driver to handle this delivery order
    return true;
  }

  /// Check if the order is assigned/scheduled for the given date (defaulting to today)
  bool isAssignedOnDate(DateTime targetDate) {
    final effectiveDate = assignedAt ?? createdAt;
    return effectiveDate.year == targetDate.year &&
        effectiveDate.month == targetDate.month &&
        effectiveDate.day == targetDate.day;
  }

  int get stepProgressDots {
    final s = normalizedStatus;
    if (s == 'DELIVERED') return 5;
    if (s == 'READY' || s == 'COMPLETED' || s == 'OUT FOR DELIVERY') return 5;
    if (s == 'PACKING') return 4;
    if (s == 'PICKING') {
      if (totalItemsCount > 0 && pickedItemsCount == totalItemsCount) {
        return 5;
      }
      return 3;
    }
    if (s == 'ASSIGNED') return 2;
    return 1;
  }

  String get stepProgressText {
    switch (normalizedStatus) {
      case 'NEW':
        return 'Awaiting Start';
      case 'PROCESSING':
        return 'Processing Order';
      case 'ASSIGNED':
        return 'Assigned to Driver';
      case 'PICKING':
        final pct = (progressPercentage * 100).round();
        return '$pct% Complete';
      case 'PACKING':
        return 'Packing Items';
      case 'READY':
        return 'Ready for Delivery';
      case 'OUT FOR DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered to Customer';
      case 'COMPLETED':
        return 'Order Completed';
      default:
        return 'In Progress';
    }
  }
}
