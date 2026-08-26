import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryOrderModel {
  final String orderId;
  final String customerId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String customerAddress;
  final double customerLatitude;
  final double customerLongitude;
  final double driverLatitude;
  final double driverLongitude;
  final String status; // 'preparing', 'assigned', 'out_for_delivery', 'delivered'
  final dynamic updatedAt;

  const DeliveryOrderModel({
    required this.orderId,
    required this.customerId,
    required this.driverId,
    this.driverName = 'Alan R. (Courier)',
    this.driverPhone = '+1 (555) 234-5678',
    required this.customerAddress,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.status,
    this.updatedAt,
  });

  bool get isPreparing => status == 'preparing';
  bool get isAssigned => status == 'assigned';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';

  /// Convert model instance to Firestore document Map
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'customerAddress': customerAddress,
      'customerLatitude': customerLatitude,
      'customerLongitude': customerLongitude,
      'driverLatitude': driverLatitude,
      'driverLongitude': driverLongitude,
      'status': status,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create model instance from Firestore DocumentSnapshot
  factory DeliveryOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeliveryOrderModel.fromMap(data, doc.id);
  }

  /// Create model instance from Map
  factory DeliveryOrderModel.fromMap(Map<String, dynamic> data, String docId) {
    return DeliveryOrderModel(
      orderId: docId,
      customerId: (data['customerId'] ?? '').toString(),
      driverId: (data['driverId'] ?? '').toString(),
      driverName: (data['driverName'] ?? 'Alan R. (Courier)').toString(),
      driverPhone: (data['driverPhone'] ?? '+1 (555) 234-5678').toString(),
      customerAddress: (data['customerAddress'] ?? '').toString(),
      customerLatitude: (data['customerLatitude'] as num?)?.toDouble() ?? 37.7749,
      customerLongitude: (data['customerLongitude'] as num?)?.toDouble() ?? -122.4194,
      driverLatitude: (data['driverLatitude'] as num?)?.toDouble() ?? 37.7790,
      driverLongitude: (data['driverLongitude'] as num?)?.toDouble() ?? -122.4140,
      status: (data['status'] ?? 'preparing').toString(),
      updatedAt: data['updatedAt'],
    );
  }

  DeliveryOrderModel copyWith({
    String? orderId,
    String? customerId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    double? driverLatitude,
    double? driverLongitude,
    String? status,
    dynamic updatedAt,
  }) {
    return DeliveryOrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
