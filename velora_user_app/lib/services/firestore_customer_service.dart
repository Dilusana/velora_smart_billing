import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';

class FirestoreCustomerService {
  static final FirestoreCustomerService instance = FirestoreCustomerService._();
  FirestoreCustomerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Create a new customer document in Firestore using uid as document ID in BOTH 'customers' AND 'users' collections
  Future<void> createCustomerProfile(CustomerModel customer) async {
    try {
      final data = customer.toMap();
      final userData = {
        ...data,
        'uid': customer.uid,
        'id': customer.uid,
        'name': customer.fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _customersRef.doc(customer.uid).set(data, SetOptions(merge: true));
      await _usersRef.doc(customer.uid).set(userData, SetOptions(merge: true));
      debugPrint('Successfully created customer profile in Firestore for UID: ${customer.uid}');
    } catch (e) {
      debugPrint('Error creating customer profile in Firestore: $e');
      rethrow;
    }
  }

  /// Get customer profile/details by UID
  Future<CustomerModel?> getCustomerProfile(String uid) async {
    try {
      final doc = await _customersRef.doc(uid).get();
      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching customer profile: $e');
      return null;
    }
  }

  /// Get customer details alias method
  Future<CustomerModel?> getCustomerDetails(String uid) => getCustomerProfile(uid);

  /// Fetch customer address string and coordinates
  Future<Map<String, dynamic>?> fetchCustomerAddress(String uid) async {
    try {
      final doc = await _customersRef.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'address': (data['address'] ?? '').toString(),
          'latitude': data['latitude'] is num ? (data['latitude'] as num).toDouble() : 0.0,
          'longitude': data['longitude'] is num ? (data['longitude'] as num).toDouble() : 0.0,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching customer address: $e');
      return null;
    }
  }

  /// Ensure customer document exists and details/lastLogin are saved in Firestore on login
  Future<CustomerModel> saveOrUpdateCustomerOnLogin(User user) async {
    try {
      final docRef = _customersRef.doc(user.uid);
      final userDocRef = _usersRef.doc(user.uid);
      final doc = await docRef.get();

      final loginUpdateData = {
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': true,
      };

      if (doc.exists) {
        await docRef.set(loginUpdateData, SetOptions(merge: true));
        await userDocRef.set(loginUpdateData, SetOptions(merge: true));
        final updatedDoc = await docRef.get();
        return CustomerModel.fromFirestore(updatedDoc);
      } else {
        final newCustomer = CustomerModel(
          uid: user.uid,
          fullName: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email != null ? user.email!.split('@').first : 'Customer'),
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          address: '',
          role: 'customer',
          isActive: true,
          isVerified: true,
        );

        final Map<String, dynamic> data = newCustomer.toMap();
        data['lastLogin'] = FieldValue.serverTimestamp();

        final Map<String, dynamic> userData = {
          ...data,
          'uid': user.uid,
          'id': user.uid,
          'name': newCustomer.fullName,
        };

        await docRef.set(data, SetOptions(merge: true));
        await userDocRef.set(userData, SetOptions(merge: true));
        return newCustomer;
      }
    } catch (e) {
      debugPrint('Error saving customer profile on login: $e');
      return CustomerModel(
        uid: user.uid,
        fullName: user.displayName ?? 'Customer',
        email: user.email ?? '',
        phone: '',
        address: '',
      );
    }
  }

  /// Stream customer profile changes in real-time
  Stream<CustomerModel?> streamCustomerProfile(String uid) {
    return _customersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update customer profile (fullName, phone, address, profileImage)
  Future<void> updateCustomerProfile({
    required String uid,
    required String fullName,
    required String phone,
    String? address,
    String? profileImage,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'fullName': fullName.trim(),
        'name': fullName.trim(),
        'phone': phone.trim(),
        'phoneNumber': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (address != null) {
        updateData['address'] = address.trim();
      }
      if (latitude != null) {
        updateData['latitude'] = latitude;
      }
      if (longitude != null) {
        updateData['longitude'] = longitude;
      }
      if (profileImage != null) {
        updateData['photoUrl'] = profileImage.trim();
        updateData['profileImage'] = profileImage.trim();
      }

      await _customersRef.doc(uid).set(updateData, SetOptions(merge: true));
      await _usersRef.doc(uid).set(updateData, SetOptions(merge: true));
      debugPrint('Successfully updated customer profile for UID: $uid');
    } catch (e) {
      debugPrint('Error updating customer profile: $e');
      rethrow;
    }
  }

  /// Update customer address with GPS coordinates (latitude, longitude)
  Future<void> updateCustomerAddress({
    required String uid,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _customersRef.doc(uid).set(updateData, SetOptions(merge: true));
      await _usersRef.doc(uid).set(updateData, SetOptions(merge: true));
      debugPrint('Successfully updated customer address and GPS coordinates for UID: $uid');
    } catch (e) {
      debugPrint('Error updating customer address: $e');
      rethrow;
    }
  }

  /// Upload/Update profile image path or URL
  Future<void> uploadProfileImage({
    required String uid,
    required String imagePath,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'photoUrl': imagePath.trim(),
        'profileImage': imagePath.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _customersRef.doc(uid).set(updateData, SetOptions(merge: true));
      await _usersRef.doc(uid).set(updateData, SetOptions(merge: true));
      debugPrint('Successfully updated profile image for UID: $uid');
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      rethrow;
    }
  }
}
