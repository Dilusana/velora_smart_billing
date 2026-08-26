import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  if (val is Timestamp) return val.toDate();
  try {
    final dynamic d = val;
    if (d.toDate != null) {
      return d.toDate() as DateTime;
    }
  } catch (_) {}
  return DateTime.tryParse(val.toString()) ?? DateTime.now();
}

double _parsePrice(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}

String _parseRefOrString(dynamic val) {
  if (val == null) return '';
  if (val is DocumentReference) {
    return val.id;
  }
  try {
    final dynamic d = val;
    if (d.path != null) {
      final String p = d.path.toString();
      final parts = p.split('/');
      return parts.isNotEmpty ? parts.last : p;
    }
    if (d.id != null) return d.id.toString();
  } catch (_) {}
  final String str = val.toString();
  if (str.contains('/')) {
    return str.split('/').last;
  }
  return str;
}

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final String unit;
  final String status;
  final String imageUrl;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.unit,
    required this.status,
    required this.imageUrl,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? price,
    double? cost,
    int? stock,
    String? unit,
    String? status,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'price': price,
      'cost': cost,
      'stock': stock,
      'unit': unit,
      'status': status,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      cost: (map['cost'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      unit: map['unit'] ?? '',
      status: map['status'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null ? _parseDateTime(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [
        id, name, sku, category, price, cost, stock, unit, status, imageUrl, description, createdAt, updatedAt
      ];
}

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final int productCount;
  final double revenueShare;
  final String description;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.productCount,
    required this.revenueShare,
    required this.description,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? productCount,
    double? revenueShare,
    String? description,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      revenueShare: revenueShare ?? this.revenueShare,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'revenueShare': revenueShare,
      'description': description,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      productCount: map['productCount'] ?? 0,
      revenueShare: (map['revenueShare'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, productCount, revenueShare, description];
}

// =============================================================================
// FIFO Models
// =============================================================================

/// Records exactly how much of a specific stock batch was consumed in a sale
/// or FIFO-consuming adjustment (damage, expired, waste).
class FifoBatchConsumption {
  final String batchId;
  final String batchNumber;
  final int quantityConsumed;
  final double unitCostPrice;
  final double totalCost; // quantityConsumed * unitCostPrice

  const FifoBatchConsumption({
    required this.batchId,
    required this.batchNumber,
    required this.quantityConsumed,
    required this.unitCostPrice,
    required this.totalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'batchNumber': batchNumber,
      'quantityConsumed': quantityConsumed,
      'unitCostPrice': unitCostPrice,
      'totalCost': totalCost,
    };
  }

  factory FifoBatchConsumption.fromMap(Map<String, dynamic> map) {
    return FifoBatchConsumption(
      batchId: map['batchId'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      quantityConsumed: (map['quantityConsumed'] as num?)?.toInt() ?? 0,
      unitCostPrice: (map['unitCostPrice'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Returned by processFifoSale after a successful FIFO deduction.
class FifoSaleResult {
  final double cogs;
  final double profit;
  final double totalRevenue;
  final List<FifoBatchConsumption> batchConsumptions;

  const FifoSaleResult({
    required this.cogs,
    required this.profit,
    required this.totalRevenue,
    required this.batchConsumptions,
  });
}

/// FIFO statistics for a single product — computed from stock_batches and
/// sale_line_items streams.
class FifoProductStats {
  final int currentStock;
  final double fifoCostPrice;    // weighted average cost of remaining stock
  final double inventoryValue;   // sum(remainingQty × purchasePrice) across active batches
  final double sellingPrice;
  final double totalCogsToDate;  // cumulative COGS from all sale_line_items
  final double estimatedProfit;  // (sellingPrice − fifoCostPrice) × currentStock

  const FifoProductStats({
    required this.currentStock,
    required this.fifoCostPrice,
    required this.inventoryValue,
    required this.sellingPrice,
    required this.totalCogsToDate,
    required this.estimatedProfit,
  });

  static const FifoProductStats empty = FifoProductStats(
    currentStock: 0,
    fifoCostPrice: 0,
    inventoryValue: 0,
    sellingPrice: 0,
    totalCogsToDate: 0,
    estimatedProfit: 0,
  );
}

/// Represents one product line in a FIFO-tracked sale, stored in the
/// 'sale_line_items' Firestore collection.
class SaleLineItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantitySold;
  final double sellingPrice;
  final double totalRevenue;
  final double cogs;
  final double profit;
  final DateTime saleDate;
  final List<FifoBatchConsumption> batchConsumptions;

  const SaleLineItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.sellingPrice,
    required this.totalRevenue,
    required this.cogs,
    required this.profit,
    required this.saleDate,
    required this.batchConsumptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantitySold': quantitySold,
      'sellingPrice': sellingPrice,
      'totalRevenue': totalRevenue,
      'cogs': cogs,
      'profit': profit,
      'saleDate': saleDate.toIso8601String(),
      'batchConsumptions': batchConsumptions.map((b) => b.toMap()).toList(),
    };
  }

  factory SaleLineItemModel.fromMap(String id, Map<String, dynamic> map) {
    return SaleLineItemModel(
      id: id,
      orderId: map['orderId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantitySold: (map['quantitySold'] as num?)?.toInt() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      cogs: (map['cogs'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      saleDate: DateTime.tryParse(map['saleDate'] ?? '') ?? DateTime.now(),
      batchConsumptions: (map['batchConsumptions'] as List<dynamic>? ?? [])
          .map((b) => FifoBatchConsumption.fromMap(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

// =============================================================================
// Order Models
// =============================================================================

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  // FIFO cost tracking — populated when order is marked Completed
  final double? cogs;   // actual FIFO cost of this line item
  final double? profit; // total - cogs
  final List<FifoBatchConsumption> batchConsumptions;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.cogs,
    this.profit,
    this.batchConsumptions = const [],
  });

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? total,
    double? cogs,
    double? profit,
    List<FifoBatchConsumption>? batchConsumptions,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      cogs: cogs ?? this.cogs,
      profit: profit ?? this.profit,
      batchConsumptions: batchConsumptions ?? this.batchConsumptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productID': productId,
      'productName': productName,
      'name': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'price': unitPrice,
      'total': total,
      if (cogs != null) 'cogs': cogs,
      if (profit != null) 'profit': profit,
      if (batchConsumptions.isNotEmpty)
        'batchConsumptions': batchConsumptions.map((b) => b.toMap()).toList(),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final pid = (map['productID'] ?? map['productId'] ?? '').toString();
    final name = (map['name'] ?? map['productName'] ?? '').toString();
    final qty = (map['quantity'] as num?)?.toInt() ?? 0;
    final price = _parsePrice(map['price'] ?? map['unitPrice']);
    final tot = (map['total'] as num?)?.toDouble() ?? (price * qty);

    return OrderItem(
      productId: pid,
      productName: name,
      quantity: qty,
      unitPrice: price,
      total: tot,
      cogs: (map['cogs'] as num?)?.toDouble(),
      profit: (map['profit'] as num?)?.toDouble(),
      batchConsumptions: (map['batchConsumptions'] as List<dynamic>? ?? [])
          .map((b) => FifoBatchConsumption.fromMap(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [productId, productName, quantity, unitPrice, total, cogs, profit];
}

class OrderModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String deliveryType;
  final String branch;
  final String branchId;
  final bool smsSent;
  final DateTime? smsSentAt;
  final String? smsId;
  final String? smsError;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.items,
    this.subtotal = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = '',
    required this.status,
    this.deliveryType = 'delivery',
    required this.branch,
    this.branchId = '',
    this.smsSent = false,
    this.smsSentAt,
    this.smsId,
    this.smsError,
    required this.createdAt,
  });

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? status,
    String? deliveryType,
    String? branch,
    String? branchId,
    bool? smsSent,
    DateTime? smsSentAt,
    String? smsId,
    String? smsError,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      deliveryType: deliveryType ?? this.deliveryType,
      branch: branch ?? this.branch,
      branchId: branchId ?? this.branchId,
      smsSent: smsSent ?? this.smsSent,
      smsSentAt: smsSentAt ?? this.smsSentAt,
      smsId: smsId ?? this.smsId,
      smsError: smsError ?? this.smsError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'deliveryType': deliveryType,
      'deliverytype': deliveryType,
      'branch': branch,
      'branchId': branchId,
      'smsSent': smsSent,
      'smsSentAt': smsSentAt?.toIso8601String(),
      'smsId': smsId,
      'smsError': smsError,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawId = docId ?? (map['id'] as String?) ?? '';
    final parsedItems = List<OrderItem>.from(
      (map['items'] as List<dynamic>? ?? [])
          .map((x) => OrderItem.fromMap(x as Map<String, dynamic>)),
    );

    final double rawSubtotal = (map['subtotal'] as num?)?.toDouble() ??
        parsedItems.fold<double>(0.0, (acc, item) => acc + item.total);
    final double rawDiscount = (map['discount'] as num?)?.toDouble() ?? 0.0;
    final double rawTotal = (map['total'] as num?)?.toDouble() ?? (rawSubtotal - rawDiscount);

    final cId = _parseRefOrString(map['customerId'] ?? map['customer']);
    final rawCustName = map['customerName'] ?? map['customer'];
    String cName = 'Customer';
    if (rawCustName is String && !rawCustName.contains('DocumentReference')) {
      cName = rawCustName.isEmpty ? 'Customer' : rawCustName;
    } else if (rawCustName != null) {
      final parsed = _parseRefOrString(rawCustName);
      cName = (parsed.isNotEmpty && !parsed.contains('DocumentReference')) ? parsed : 'Customer';
    }

    final bId = _parseRefOrString(map['branchId'] ?? map['branch']);
    final rawUserOrBranch = map['users'] ??
        map['user'] ??
        map['employeeName'] ??
        map['employee'] ??
        map['userName'] ??
        map['processedBy'] ??
        map['createdBy'] ??
        map['branch'] ??
        map['branchId'];
    String bName = 'Main Branch';
    if (rawUserOrBranch is String && !rawUserOrBranch.contains('DocumentReference')) {
      bName = rawUserOrBranch.isEmpty ? 'Main Branch' : rawUserOrBranch;
    } else if (rawUserOrBranch != null) {
      final parsed = _parseRefOrString(rawUserOrBranch);
      bName = (parsed.isNotEmpty && !parsed.contains('DocumentReference')) ? parsed : 'Main Branch';
    }
    if (bName != 'Main Branch' && bName.isNotEmpty && bName != 'branches') {
      bName = bName[0].toUpperCase() + bName.substring(1);
    }

    final pStatus = (map['paymentStatus'] ?? '').toString();
    final pMethod = (map['paymentMethod'] ?? (pStatus.isNotEmpty ? pStatus : 'Cash')).toString();
    final delType = (map['deliveryType'] ?? map['deliverytype'] ?? (map['deliveryFee'] != null && (map['deliveryFee'] as num) > 0 ? 'delivery' : 'pickup')).toString();

    final bool smsSent = (map['smsSent'] as bool?) ?? false;
    final String cPhone = (map['customerPhone'] ?? map['phone'] ?? '').toString();
    final String? smsId = map['smsId'] as String?;
    final String? smsError = map['smsError'] as String?;
    final DateTime? smsSentAt = map['smsSentAt'] != null ? _parseDateTime(map['smsSentAt']) : null;

    return OrderModel(
      id: rawId,
      customerId: cId.isEmpty ? 'cust-1' : cId,
      customerName: cName,
      customerPhone: cPhone,
      items: parsedItems,
      subtotal: rawSubtotal,
      discount: rawDiscount,
      total: rawTotal,
      paymentMethod: pMethod,
      paymentStatus: pStatus,
      status: (map['status'] ?? 'pending').toString(),
      deliveryType: delType,
      branch: bName,
      branchId: bId,
      smsSent: smsSent,
      smsSentAt: smsSentAt,
      smsId: smsId,
      smsError: smsError,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id, customerId, customerName, customerPhone, items, subtotal, discount, total, paymentMethod, paymentStatus, status, deliveryType, branch, branchId, smsSent, smsSentAt, smsId, smsError, createdAt
      ];
}

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int totalOrders;
  final double totalSpend;
  final String loyaltyTier;
  final int loyaltyPoints;
  final DateTime lastOrderDate;
  final String status;
  final String address;
  final DateTime joinDate;

  String get tier => loyaltyTier;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalOrders,
    required this.totalSpend,
    required this.loyaltyTier,
    this.loyaltyPoints = 0,
    required this.lastOrderDate,
    required this.status,
    required this.address,
    required this.joinDate,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? totalOrders,
    double? totalSpend,
    String? loyaltyTier,
    int? loyaltyPoints,
    DateTime? lastOrderDate,
    String? status,
    String? address,
    DateTime? joinDate,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpend: totalSpend ?? this.totalSpend,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      status: status ?? this.status,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'totalOrders': totalOrders,
      'totalSpend': totalSpend,
      'loyaltyTier': loyaltyTier,
      'loyaltyPoints': loyaltyPoints,
      'lastOrderDate': lastOrderDate.toIso8601String(),
      'status': status,
      'address': address,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawId = docId ?? (map['id'] as String?) ?? '';
    final pts = (map['loyaltyPoints'] as num?)?.toInt() ?? 0;
    String rawTier = (map['loyaltyTier'] as String?) ?? '';
    if (rawTier.isEmpty) {
      if (pts >= 1000) {
        rawTier = 'Platinum';
      } else if (pts >= 500) {
        rawTier = 'Gold';
      } else if (pts >= 100) {
        rawTier = 'Silver';
      } else {
        rawTier = 'Bronze';
      }
    }

    return CustomerModel(
      id: rawId,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpend: (map['totalSpend'] as num?)?.toDouble() ?? 0.0,
      loyaltyTier: rawTier,
      loyaltyPoints: pts,
      lastOrderDate: _parseDateTime(map['lastOrderDate']),
      status: (map['status'] ?? 'Active').toString(),
      address: (map['address'] ?? '').toString(),
      joinDate: _parseDateTime(map['joinDate']),
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, totalOrders, totalSpend, loyaltyTier, loyaltyPoints, lastOrderDate, status, address, joinDate
      ];
}

class PaymentModel extends Equatable {
  final String id;
  final String transactionId;
  final String paymentId;
  final String invoiceNumber;
  final String orderId;
  final String customerId;
  final String customerName;
  final double amount;
  final double refundAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String refundStatus;
  final String processedBy;
  final DateTime paymentDate;
  final DateTime createdAt;

  String get customer => customerName;
  String get method => paymentMethod;
  String get status => paymentStatus;
  DateTime get date => paymentDate;

  PaymentModel({
    required this.id,
    this.transactionId = '',
    this.paymentId = '',
    this.invoiceNumber = '',
    required this.orderId,
    this.customerId = '',
    String customerName = '',
    String customer = '',
    required this.amount,
    this.refundAmount = 0.0,
    String paymentMethod = '',
    String method = '',
    String paymentStatus = '',
    String status = '',
    this.refundStatus = 'Not Refunded',
    this.processedBy = '',
    DateTime? paymentDate,
    DateTime? createdAt,
  })  : customerName = customerName.isNotEmpty ? customerName : (customer.isNotEmpty ? customer : 'Customer'),
        paymentMethod = paymentMethod.isNotEmpty ? paymentMethod : (method.isNotEmpty ? method : 'Cash'),
        paymentStatus = paymentStatus.isNotEmpty ? paymentStatus : (status.isNotEmpty ? status : 'paid'),
        paymentDate = paymentDate ?? createdAt ?? DateTime.now(),
        createdAt = createdAt ?? paymentDate ?? DateTime.now();

  PaymentModel copyWith({
    String? id,
    String? transactionId,
    String? paymentId,
    String? invoiceNumber,
    String? orderId,
    String? customerId,
    String? customerName,
    String? customer,
    double? amount,
    double? refundAmount,
    String? paymentMethod,
    String? method,
    String? paymentStatus,
    String? status,
    String? refundStatus,
    String? processedBy,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      paymentId: paymentId ?? this.paymentId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? customer ?? this.customerName,
      amount: amount ?? this.amount,
      refundAmount: refundAmount ?? this.refundAmount,
      paymentMethod: paymentMethod ?? method ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? status ?? this.paymentStatus,
      refundStatus: refundStatus ?? this.refundStatus,
      processedBy: processedBy ?? this.processedBy,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId.isNotEmpty ? paymentId : id,
      'transactionId': transactionId.isNotEmpty ? transactionId : id,
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customer': customerName,
      'amount': amount,
      'refundAmount': refundAmount,
      'paymentMethod': paymentMethod,
      'method': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': paymentStatus,
      'refundStatus': refundStatus,
      'processedBy': processedBy,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawId = docId ?? (map['id'] as String?) ?? (map['paymentId'] as String?) ?? (map['transactionId'] as String?) ?? '';
    final transIdRaw = map['transactionId'] ?? rawId;
    final transId = transIdRaw is String && !transIdRaw.contains('DocumentReference')
        ? transIdRaw
        : _parseRefOrString(transIdRaw);
    final payIdRaw = map['paymentId'] ?? rawId;
    final payId = payIdRaw is String && !payIdRaw.contains('DocumentReference')
        ? payIdRaw
        : _parseRefOrString(payIdRaw);
    final invNum = (map['invoiceNumber'] ?? '').toString();
    final oId = _parseRefOrString(map['orderId'] ?? map['order']);
    final cId = _parseRefOrString(map['customerId'] ?? map['customer']);

    final rawCustName = map['customerName'] ?? map['customer'];
    String cName = 'Customer';
    if (rawCustName is String && !rawCustName.contains('DocumentReference')) {
      cName = rawCustName.isEmpty ? 'Customer' : rawCustName;
    } else if (rawCustName != null) {
      final parsed = _parseRefOrString(rawCustName);
      cName = (parsed.isNotEmpty && !parsed.contains('DocumentReference')) ? parsed : 'Customer';
    }

    final amt = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final refAmt = (map['refundAmount'] as num?)?.toDouble() ?? 0.0;

    final rawMethod = map['paymentMethod'] ?? map['method'];
    String pMethod = 'Cash';
    if (rawMethod is String && !rawMethod.contains('DocumentReference')) {
      pMethod = rawMethod.isEmpty ? 'Cash' : rawMethod;
    } else if (rawMethod != null) {
      final parsed = _parseRefOrString(rawMethod);
      pMethod = (parsed.isNotEmpty && !parsed.contains('DocumentReference')) ? parsed : 'Cash';
    }

    final pStatus = (map['paymentStatus'] ?? map['status'] ?? 'paid').toString();
    final rStatus = (map['refundStatus'] ?? 'Not Refunded').toString();
    final pBy = _parseRefOrString(map['processedBy']);
    final pDate = _parseDateTime(map['paymentDate'] ?? map['createdAt']);
    final cDate = _parseDateTime(map['createdAt'] ?? map['paymentDate']);

    return PaymentModel(
      id: rawId.isEmpty ? payId : rawId,
      transactionId: transId,
      paymentId: payId,
      invoiceNumber: invNum,
      orderId: oId,
      customerId: cId,
      customerName: cName,
      amount: amt,
      refundAmount: refAmt,
      paymentMethod: pMethod,
      paymentStatus: pStatus,
      refundStatus: rStatus,
      processedBy: pBy,
      paymentDate: pDate,
      createdAt: cDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        paymentId,
        invoiceNumber,
        orderId,
        customerId,
        customerName,
        amount,
        refundAmount,
        paymentMethod,
        paymentStatus,
        refundStatus,
        processedBy,
        paymentDate,
        createdAt,
      ];
}

class SupplierModel extends Equatable {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String status;
  final List<String> categories;
  final int activePOs;
  final double rating;

  String get name => companyName;
  // ignore: non_constant_identifier_names
  String get contact_person => contactPerson;
  // ignore: non_constant_identifier_names
  int get active_pos => activePOs;

  const SupplierModel({
    required this.id,
    String companyName = '',
    String name = '',
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.address = '',
    this.status = 'active',
    this.categories = const [],
    this.activePOs = 0,
    this.rating = 5.0,
  })  : companyName = companyName != '' ? companyName : (name != '' ? name : 'Supplier');

  SupplierModel copyWith({
    String? id,
    String? companyName,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? status,
    List<String>? categories,
    int? activePOs,
    double? rating,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      companyName: companyName ?? name ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      status: status ?? this.status,
      categories: categories ?? this.categories,
      activePOs: activePOs ?? this.activePOs,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'name': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'status': status,
      'categories': categories,
      'activePOs': activePOs,
      'rating': rating,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawId = docId ?? (map['id'] as String?) ?? '';
    final compName = (map['companyName'] ?? map['name'] ?? '').toString();
    final cPerson = (map['contactPerson'] ?? map['contact_person'] ?? '').toString();
    final ph = (map['phone'] ?? '').toString();
    final em = (map['email'] ?? '').toString();
    final addr = (map['address'] ?? '').toString();
    final stat = (map['status'] ?? 'active').toString();
    final cats = List<String>.from(map['categories'] ?? []);
    final pos = (map['activePOs'] as num?)?.toInt() ?? (map['active_pos'] as num?)?.toInt() ?? 0;
    final rat = (map['rating'] as num?)?.toDouble() ?? 5.0;

    return SupplierModel(
      id: rawId,
      companyName: compName.isEmpty ? 'Supplier' : compName,
      contactPerson: cPerson,
      phone: ph,
      email: em,
      address: addr,
      status: stat,
      categories: cats,
      activePOs: pos,
      rating: rat,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        contactPerson,
        phone,
        email,
        address,
        status,
        categories,
        activePOs,
        rating,
      ];
}

class SaleModel extends Equatable {
  final String id;
  final String orderId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String orderSource; // "Kiosk", "App", "Web"
  final String orderStatus;
  final String paymentStatus;
  final double totalAmount;
  final DateTime orderDate;

  const SaleModel({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.customerId,
    this.customerName = 'Customer',
    required this.orderSource,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.orderDate,
  });

  SaleModel copyWith({
    String? id,
    String? orderId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? orderSource,
    String? orderStatus,
    String? paymentStatus,
    double? totalAmount,
    DateTime? orderDate,
  }) {
    return SaleModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderSource: orderSource ?? this.orderSource,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'orderSource': orderSource,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawId = docId ?? (map['id'] as String?) ?? '';
    final oId = _parseRefOrString(map['orderId']);
    final invNum = _parseRefOrString(map['invoiceNumber']);
    final cId = _parseRefOrString(map['customerId']);
    final cName = (map['customerName'] ?? map['customer'] ?? '').toString();
    final source = (map['orderSource'] ?? map['source'] ?? 'Kiosk').toString();
    final oStatus = (map['orderStatus'] ?? map['status'] ?? 'completed').toString();
    final pStatus = (map['paymentStatus'] ?? 'paid').toString();
    final total = (map['totalAmount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0;
    final date = _parseDateTime(map['orderDate'] ?? map['createdAt']);

    return SaleModel(
      id: rawId.isEmpty ? (oId.isEmpty ? 'sale-1' : oId) : rawId,
      orderId: oId.isEmpty ? rawId : oId,
      invoiceNumber: invNum.isEmpty ? (oId.isNotEmpty ? oId : rawId) : invNum,
      customerId: cId,
      customerName: cName.isEmpty ? 'Customer' : cName,
      orderSource: source.isEmpty ? 'Kiosk' : source,
      orderStatus: oStatus,
      paymentStatus: pStatus,
      totalAmount: total,
      orderDate: date,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        invoiceNumber,
        customerId,
        customerName,
        orderSource,
        orderStatus,
        paymentStatus,
        totalAmount,
        orderDate,
      ];
}

class InventoryItemModel extends Equatable {
  final String productId;
  final String productName;
  final int currentStock;
  final int reorderLevel;
  final String warehouse;
  final DateTime lastRestocked;
  final String status;

  const InventoryItemModel({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.reorderLevel,
    required this.warehouse,
    required this.lastRestocked,
    required this.status,
  });

  InventoryItemModel copyWith({
    String? productId,
    String? productName,
    int? currentStock,
    int? reorderLevel,
    String? warehouse,
    DateTime? lastRestocked,
    String? status,
  }) {
    return InventoryItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      warehouse: warehouse ?? this.warehouse,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'reorderLevel': reorderLevel,
      'warehouse': warehouse,
      'lastRestocked': lastRestocked.toIso8601String(),
      'status': status,
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      currentStock: map['currentStock'] ?? 0,
      reorderLevel: map['reorderLevel'] ?? 0,
      warehouse: map['warehouse'] ?? '',
      lastRestocked: DateTime.tryParse(map['lastRestocked'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? '',
    );
  }

  @override
  List<Object?> get props => [productId, productName, currentStock, reorderLevel, warehouse, lastRestocked, status];
}

class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String type;
  final int quantity;
  final String reason;
  final String note;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  StockMovement copyWith({
    String? id,
    String? productId,
    String? type,
    int? quantity,
    String? reason,
    String? note,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      type: map['type'] ?? '',
      quantity: map['quantity'] ?? 0,
      reason: map['reason'] ?? '',
      note: map['note'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, productId, type, quantity, reason, note, createdAt];
}

/// Represents a single stock purchase batch (received from a supplier)
class StockBatchModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String supplierId;
  final String supplierName;
  final int quantity;
  final int remainingQty;
  final double purchasePrice;
  final DateTime purchaseDate;
  final DateTime productionDate;
  final DateTime expiryDate;
  final int expiryDays;
  final String batchNumber;
  final String status; // 'active' | 'expired' | 'depleted'
  final DateTime createdAt;

  const StockBatchModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.remainingQty,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.productionDate,
    required this.expiryDate,
    required this.expiryDays,
    required this.batchNumber,
    required this.status,
    required this.createdAt,
  });

  /// Returns 'Expired', 'Expiring Soon' (≤5 days), or 'Normal'
  String get expiryStatus {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return 'Expired';
    if (diff <= 5) return 'Expiring Soon';
    return 'Normal';
  }

  StockBatchModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? supplierId,
    String? supplierName,
    int? quantity,
    int? remainingQty,
    double? purchasePrice,
    DateTime? purchaseDate,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? expiryDays,
    String? batchNumber,
    String? status,
    DateTime? createdAt,
  }) {
    return StockBatchModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      quantity: quantity ?? this.quantity,
      remainingQty: remainingQty ?? this.remainingQty,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      expiryDays: expiryDays ?? this.expiryDays,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'quantity': quantity,
      'remainingQty': remainingQty,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'productionDate': productionDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'expiryDays': expiryDays,
      'batchNumber': batchNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockBatchModel.fromMap(String id, Map<String, dynamic> map) {
    return StockBatchModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      remainingQty: (map['remainingQty'] as num?)?.toInt() ?? 0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.tryParse(map['purchaseDate'] ?? '') ?? DateTime.now(),
      productionDate: DateTime.tryParse(map['productionDate'] ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(map['expiryDate'] ?? '') ?? DateTime.now(),
      expiryDays: (map['expiryDays'] as num?)?.toInt() ?? 0,
      batchNumber: map['batchNumber'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id, productId, productName, supplierId, supplierName,
        quantity, remainingQty, purchasePrice, purchaseDate,
        productionDate, expiryDate, expiryDays, batchNumber, status, createdAt,
      ];
}

/// Represents a manual stock adjustment event
class StockAdjustmentModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'add' | 'remove'
  final int quantity;
  final String reason; // Restock, Damage, Expired, Spoiled, Waste, Return, Correction, Other
  final String notes;
  final String adjustedBy;
  final DateTime createdAt;

  /// Populated for FIFO-consuming removal reasons (Damage, Expired, Spoiled, Waste).
  /// Records exactly which batches were consumed.
  final List<FifoBatchConsumption> batchConsumptions;

  const StockAdjustmentModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.notes,
    required this.adjustedBy,
    required this.createdAt,
    this.batchConsumptions = const [],
  });

  /// Returns true for reasons that consume stock from FIFO batches.
  static bool isFifoReason(String reason) {
    const fifoReasons = {'Damage', 'Expired', 'Spoiled', 'Waste'};
    return fifoReasons.contains(reason);
  }

  StockAdjustmentModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? type,
    int? quantity,
    String? reason,
    String? notes,
    String? adjustedBy,
    DateTime? createdAt,
    List<FifoBatchConsumption>? batchConsumptions,
  }) {
    return StockAdjustmentModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      adjustedBy: adjustedBy ?? this.adjustedBy,
      createdAt: createdAt ?? this.createdAt,
      batchConsumptions: batchConsumptions ?? this.batchConsumptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'notes': notes,
      'adjustedBy': adjustedBy,
      'createdAt': createdAt.toIso8601String(),
      if (batchConsumptions.isNotEmpty)
        'batchConsumptions': batchConsumptions.map((b) => b.toMap()).toList(),
    };
  }

  factory StockAdjustmentModel.fromMap(String id, Map<String, dynamic> map) {
    return StockAdjustmentModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: map['type'] ?? 'add',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      reason: map['reason'] ?? '',
      notes: map['notes'] ?? '',
      adjustedBy: map['adjustedBy'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      batchConsumptions: (map['batchConsumptions'] as List<dynamic>? ?? [])
          .map((b) => FifoBatchConsumption.fromMap(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [id, productId, productName, type, quantity, reason, notes, adjustedBy, createdAt];
}

class PromotionModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final double value;
  final String scope;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int usageCount;
  final String couponCode;
  final String description;
  final double minimumPurchaseAmount;
  final double maximumDiscount;
  final List<String> applicableProducts;
  final List<String> applicableCategories;

  bool get isActive => status.toLowerCase() == 'active';

  const PromotionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.scope,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.usageCount,
    required this.couponCode,
    this.description = '',
    this.minimumPurchaseAmount = 0.0,
    this.maximumDiscount = 0.0,
    this.applicableProducts = const [],
    this.applicableCategories = const [],
  });

  PromotionModel copyWith({
    String? id,
    String? name,
    String? type,
    double? value,
    String? scope,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? usageCount,
    String? couponCode,
    String? description,
    double? minimumPurchaseAmount,
    double? maximumDiscount,
    List<String>? applicableProducts,
    List<String>? applicableCategories,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      scope: scope ?? this.scope,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      usageCount: usageCount ?? this.usageCount,
      couponCode: couponCode ?? this.couponCode,
      description: description ?? this.description,
      minimumPurchaseAmount: minimumPurchaseAmount ?? this.minimumPurchaseAmount,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      applicableCategories: applicableCategories ?? this.applicableCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Promotion ID': couponCode.isNotEmpty ? couponCode : id,
      'Promotion Name': name,
      'name': name,
      'Promotion_Type': type,
      'type': type,
      'Discount_Value': value,
      'value': value,
      'scope': scope,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(startDate),
      'status': status,
      'usageCount': usageCount,
      'usage': usageCount,
      'couponCode': couponCode,
      'Description': description,
      'minimumPurchaseAmount': minimumPurchaseAmount,
      'maximumDiscount': maximumDiscount,
      'Applicable_Products': applicableProducts,
      'applicable_Categories': applicableCategories,
    };
  }

  factory PromotionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    try {
      final rawId = docId ?? (map['id'] as String?) ?? (map['Promotion ID'] as String?) ?? '';
      final name = (map['Promotion Name'] ?? map['name'] ?? map['couponCode'] ?? '').toString();
      final type = (map['Promotion_Type'] ?? map['type'] ?? map['Promotion Type'] ?? 'Discount %').toString();
      final val = _parsePrice(map['Discount_Value'] ?? map['value'] ?? map['Discount Value']);

      final rawProducts = map['Applicable_Products'] ?? map['applicableProducts'] ?? map['Applicable Products'];
      final List<String> appProducts = [];
      if (rawProducts is List) {
        for (final item in rawProducts) {
          final s = _parseRefOrString(item);
          if (s.isNotEmpty) appProducts.add(s);
        }
      }

      final rawCategories = map['applicable_Categories'] ?? map['applicableCategories'] ?? map['Applicable Categories'];
      final List<String> appCategories = [];
      if (rawCategories is List) {
        for (final item in rawCategories) {
          final s = _parseRefOrString(item);
          if (s.isNotEmpty) appCategories.add(s);
        }
      }

      String scope = (map['scope'] ?? '').toString();
      if (scope.isEmpty) {
        if (appProducts.isNotEmpty) {
          scope = 'Specific Products';
        } else if (appCategories.isNotEmpty) {
          scope = 'Specific Category';
        } else {
          scope = 'All Products';
        }
      }

      final sDate = _parseDateTime(map['startDate'] ?? map['start_date'] ?? map['Start Date'] ?? map['createdAt']);
      final eDate = _parseDateTime(map['endDate'] ?? map['end_date'] ?? map['End Date']);
      final stat = (map['status'] ?? 'active').toString();
      final usage = (map['usageCount'] as num?)?.toInt() ?? (map['usage'] as num?)?.toInt() ?? 0;
      final code = (map['Promotion ID'] ?? map['couponCode'] ?? map['code'] ?? rawId).toString();
      final desc = (map['Description'] ?? map['description'] ?? '').toString();
      final minPurchase = _parsePrice(map['minimumPurchaseAmount'] ?? map['minPurchase']);
      final maxDiscount = _parsePrice(map['maximumDiscount'] ?? map['maxDiscount']);

      return PromotionModel(
        id: rawId.isEmpty ? 'promo-1' : rawId,
        name: name.isEmpty ? 'Promotion' : name,
        type: type.isEmpty ? 'Discount %' : type,
        value: val,
        scope: scope,
        startDate: sDate,
        endDate: eDate,
        status: stat,
        usageCount: usage,
        couponCode: code,
        description: desc,
        minimumPurchaseAmount: minPurchase,
        maximumDiscount: maxDiscount,
        applicableProducts: appProducts,
        applicableCategories: appCategories,
      );
    } catch (_) {
      return PromotionModel(
        id: docId ?? 'promo-1',
        name: map['Promotion Name']?.toString() ?? 'Promotion',
        type: map['Promotion_Type']?.toString() ?? 'Discount %',
        value: 0.0,
        scope: 'All Products',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: map['status']?.toString() ?? 'active',
        usageCount: 0,
        couponCode: map['Promotion ID']?.toString() ?? docId ?? '',
      );
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        value,
        scope,
        startDate,
        endDate,
        status,
        usageCount,
        couponCode,
        description,
        minimumPurchaseAmount,
        maximumDiscount,
        applicableProducts,
        applicableCategories,
      ];
}

class EmployeeModel extends Equatable {
  final String id;
  final String name;
  final String role;
  final String branch;
  final String phone;
  final String email;
  final String status;
  final DateTime hireDate;
  final double salary;
  final List<String> permissions;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.phone,
    required this.email,
    required this.status,
    required this.hireDate,
    required this.salary,
    required this.permissions,
  });

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? role,
    String? branch,
    String? phone,
    String? email,
    String? status,
    DateTime? hireDate,
    double? salary,
    List<String>? permissions,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ID': id,
      'name': name,
      'full_name': name,
      'role': role,
      'branch': branch,
      'phone': phone,
      'phone_number': phone,
      'email': email,
      'status': status,
      'hireDate': hireDate.toIso8601String(),
      'salary': salary,
      'permissions': permissions,
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final idVal = (map['id'] ?? map['ID'] ?? docId ?? '').toString();
    final nameVal = (map['name'] ?? map['full_name'] ?? map['fullName'] ?? map['userName'] ?? map['username'] ?? '').toString();
    final emailVal = (map['email'] ?? '').toString();
    final roleVal = (map['role'] ?? map['designation'] ?? map['userType'] ?? 'Staff').toString();
    final branchVal = (map['branch'] ?? map['store'] ?? map['assigned_zone'] ?? 'Main Branch').toString();
    final phoneVal = (map['phone'] ?? map['phone_number'] ?? map['phoneNumber'] ?? map['mobile'] ?? '').toString();
    final statusVal = (map['status'] ?? map['attendance_status'] ?? 'Active').toString();
    
    DateTime hire;
    if (map['hireDate'] != null) {
      hire = _parseDateTime(map['hireDate']);
    } else if (map['created_at'] != null) {
      hire = _parseDateTime(map['created_at']);
    } else {
      hire = DateTime.now();
    }

    final double sal = map['salary'] != null 
        ? _parsePrice(map['salary']) 
        : _parsePrice(map['earnings_today']);

    final perms = map['permissions'] != null 
        ? List<String>.from(map['permissions']) 
        : <String>['sales'];

    return EmployeeModel(
      id: idVal,
      name: nameVal.isNotEmpty ? nameVal : (emailVal.isNotEmpty ? emailVal.split('@').first : 'Employee'),
      role: roleVal.isNotEmpty ? roleVal : 'Staff',
      branch: branchVal.isNotEmpty ? branchVal : 'Main Branch',
      phone: phoneVal,
      email: emailVal,
      status: statusVal.isNotEmpty ? statusVal : 'Active',
      hireDate: hire,
      salary: sal,
      permissions: perms,
    );
  }

  @override
  List<Object?> get props => [id, name, role, branch, phone, email, status, hireDate, salary, permissions];
}

class PurchaseOrder extends Equatable {
  final String id;
  final String supplierId;
  final List<OrderItem> items;
  final String status;
  final double total;
  final DateTime expectedDate;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.items,
    required this.status,
    required this.total,
    required this.expectedDate,
  });

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    List<OrderItem>? items,
    String? status,
    double? total,
    DateTime? expectedDate,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      items: items ?? this.items,
      status: status ?? this.status,
      total: total ?? this.total,
      expectedDate: expectedDate ?? this.expectedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'items': items.map((x) => x.toMap()).toList(),
      'status': status,
      'total': total,
      'expectedDate': expectedDate.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] ?? '',
      supplierId: map['supplierId'] ?? '',
      items: List<OrderItem>.from(
        (map['items'] as List<dynamic>? ?? []).map((x) => OrderItem.fromMap(x)),
      ),
      status: map['status'] ?? '',
      total: (map['total'] ?? 0.0).toDouble(),
      expectedDate: DateTime.tryParse(map['expectedDate'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, supplierId, items, status, total, expectedDate];
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, isRead, createdAt];
}

class FaqModel extends Equatable {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  FaqModel copyWith({
    String? id,
    String? category,
    String? question,
    String? answer,
  }) {
    return FaqModel(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answer': answer,
    };
  }

  factory FaqModel.fromMap(Map<String, dynamic> map) {
    return FaqModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, category, question, answer];
}

class DashboardStats extends Equatable {
  final double todaySales;
  final int todayOrders;
  final int totalProducts;
  final int lowStockCount;
  final int totalCustomers;
  final double monthlyRevenue;

  const DashboardStats({
    required this.todaySales,
    required this.todayOrders,
    required this.totalProducts,
    required this.lowStockCount,
    required this.totalCustomers,
    required this.monthlyRevenue,
  });

  DashboardStats copyWith({
    double? todaySales,
    int? todayOrders,
    int? totalProducts,
    int? lowStockCount,
    int? totalCustomers,
    double? monthlyRevenue,
  }) {
    return DashboardStats(
      todaySales: todaySales ?? this.todaySales,
      todayOrders: todayOrders ?? this.todayOrders,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'todaySales': todaySales,
      'todayOrders': todayOrders,
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'totalCustomers': totalCustomers,
      'monthlyRevenue': monthlyRevenue,
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      todaySales: (map['todaySales'] ?? 0.0).toDouble(),
      todayOrders: map['todayOrders'] ?? 0,
      totalProducts: map['totalProducts'] ?? 0,
      lowStockCount: map['lowStockCount'] ?? 0,
      totalCustomers: map['totalCustomers'] ?? 0,
      monthlyRevenue: (map['monthlyRevenue'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [todaySales, todayOrders, totalProducts, lowStockCount, totalCustomers, monthlyRevenue];
}

class SalesChartData extends Equatable {
  final double x;
  final double y;

  const SalesChartData({required this.x, required this.y});

  SalesChartData copyWith({double? x, double? y}) {
    return SalesChartData(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory SalesChartData.fromMap(Map<String, dynamic> map) {
    return SalesChartData(
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [x, y];
}

class RevenueDistributionItem extends Equatable {
  final String categoryName;
  final double percentage;

  const RevenueDistributionItem({
    required this.categoryName,
    required this.percentage,
  });

  RevenueDistributionItem copyWith({
    String? categoryName,
    double? percentage,
  }) {
    return RevenueDistributionItem(
      categoryName: categoryName ?? this.categoryName,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'percentage': percentage,
    };
  }

  factory RevenueDistributionItem.fromMap(Map<String, dynamic> map) {
    return RevenueDistributionItem(
      categoryName: map['categoryName'] ?? '',
      percentage: (map['percentage'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [categoryName, percentage];
}

class BestSellingProduct extends Equatable {
  final String name;
  final int units;

  const BestSellingProduct({
    required this.name,
    required this.units,
  });

  BestSellingProduct copyWith({
    String? name,
    int? units,
  }) {
    return BestSellingProduct(
      name: name ?? this.name,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'units': units,
    };
  }

  factory BestSellingProduct.fromMap(Map<String, dynamic> map) {
    return BestSellingProduct(
      name: map['name'] ?? '',
      units: map['units'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [name, units];
}

class PaymentSummaryItem extends Equatable {
  final String method;
  final double total;

  const PaymentSummaryItem({
    required this.method,
    required this.total,
  });

  PaymentSummaryItem copyWith({
    String? method,
    double? total,
  }) {
    return PaymentSummaryItem(
      method: method ?? this.method,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'total': total,
    };
  }

  factory PaymentSummaryItem.fromMap(Map<String, dynamic> map) {
    return PaymentSummaryItem(
      method: map['method'] ?? '',
      total: (map['total'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [method, total];
}
