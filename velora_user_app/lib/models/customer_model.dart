import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final String role;
  final bool isActive;
  final bool isVerified;
  final dynamic createdAt;

  const CustomerModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.photoUrl = '',
    this.role = 'customer',
    this.isActive = true,
    this.isVerified = true,
    this.createdAt,
  });

  String get phoneNumber => phone;
  String get profileImage => photoUrl;

  /// Convert CustomerModel instance to Firestore document Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'phone': phone,
      'phoneNumber': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'profileImage': photoUrl,
      'role': role,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create CustomerModel instance from Firestore document snapshot
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final nameVal = (data['fullName'] ?? data['name'] ?? data['displayName'] ?? '').toString();
    final phoneVal = (data['phone'] ?? data['phoneNumber'] ?? data['mobile'] ?? data['contact'] ?? '').toString();
    final imgVal = (data['photoUrl'] ?? data['imageUrl'] ?? data['profileImage'] ?? data['avatar'] ?? data['image'] ?? '').toString();
    final latVal = data['latitude'] is num ? (data['latitude'] as num).toDouble() : 0.0;
    final lngVal = data['longitude'] is num ? (data['longitude'] as num).toDouble() : 0.0;
    final isVer = data['isVerified'] is bool ? data['isVerified'] as bool : true;

    return CustomerModel(
      uid: doc.id,
      fullName: nameVal,
      email: (data['email'] ?? '').toString(),
      phone: phoneVal,
      address: (data['address'] ?? '').toString(),
      latitude: latVal,
      longitude: lngVal,
      photoUrl: imgVal,
      role: (data['role'] ?? 'customer').toString(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      isVerified: isVer,
      createdAt: data['createdAt'],
    );
  }

  CustomerModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? isVerified,
    dynamic createdAt,
  }) {
    return CustomerModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
