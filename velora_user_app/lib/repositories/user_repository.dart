import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final int totalOrders;
  final double totalSpend;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.totalOrders = 0,
    this.totalSpend = 0.0,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return UserProfile(
      id: doc.id,
      name: (data['name'] ?? 'Alex Johnson').toString(),
      email: (data['email'] ?? 'alex.johnson@example.com').toString(),
      phone: (data['phone'] ?? '+1 (555) 234-5678').toString(),
      address: (data['address'] ?? '742 Evergreen Terrace, Springfield').toString(),
      totalOrders: parseInt(data['totalOrders']),
      totalSpend: parseDouble(data['totalSpend']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'totalOrders': totalOrders,
      'totalSpend': totalSpend,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    int? totalOrders,
    double? totalSpend,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpend: totalSpend ?? this.totalSpend,
    );
  }
}

class UserRepository {
  static final UserRepository instance = UserRepository._();

  UserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _customersRef => _firestore.collection('customers');
  CollectionReference get _usersRef => _firestore.collection('users');

  static const String defaultUserId = 'cust_user_app_01';

  static const UserProfile fallbackProfile = UserProfile(
    id: defaultUserId,
    name: 'Alex Johnson',
    email: 'alex.johnson@example.com',
    phone: '+1 (555) 234-5678',
    address: '742 Evergreen Terrace, Springfield',
    totalOrders: 12,
    totalSpend: 485.50,
  );

  /// Streams user profile from Firestore
  Stream<UserProfile> getUserProfileStream({String userId = defaultUserId}) {
    return _customersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return fallbackProfile;
      }
      return UserProfile.fromFirestore(doc);
    }).handleError((_) => fallbackProfile);
  }

  /// Saves or updates user profile in Firestore
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final data = {
        'id': profile.id,
        'uid': profile.id,
        'name': profile.name,
        'fullName': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'address': profile.address,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _customersRef.doc(profile.id).set(data, SetOptions(merge: true));
      await _usersRef.doc(profile.id).set(data, SetOptions(merge: true));
    } catch (_) {}
  }
}
