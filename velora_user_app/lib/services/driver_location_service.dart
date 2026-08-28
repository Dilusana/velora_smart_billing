import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationService {
  static final DriverLocationService instance = DriverLocationService._();
  DriverLocationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Request and check location permissions
  Future<bool> checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  /// Start live location tracking stream for an active order
  Future<bool> startLiveLocationTracking(String orderId) async {
    final hasPermission = await checkAndRequestLocationPermission();
    if (!hasPermission) {
      return false;
    }

    // Cancel any existing subscription
    await stopLiveLocationTracking();

    _isTracking = true;
    debugPrint('Starting live location tracking for Order ID: $orderId');

    // Configure Geolocator location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        await _updateDriverCoordinatesInFirestore(
          orderId: orderId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      onError: (error) {
        debugPrint('Error in driver location stream: $error');
      },
    );

    return true;
  }

  /// Update driver's latitude and longitude in Firestore orders collection
  Future<void> _updateDriverCoordinatesInFirestore({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).set(
        {
          'driverLatitude': latitude,
          'driverLongitude': longitude,
          'status': 'out_for_delivery',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Driver coordinates updated in Firestore: Lat $latitude, Lng $longitude');
    } catch (e) {
      debugPrint('Failed to update driver coordinates in Firestore: $e');
    }
  }

  /// Update order status in Firestore (e.g. 'out_for_delivery', 'delivered')
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).set(
        {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (status == 'delivered') {
        await stopLiveLocationTracking();
      }
      debugPrint('Order $orderId status updated to: $status');
    } catch (e) {
      debugPrint('Failed to update order status: $e');
      rethrow;
    }
  }

  /// Stop location tracking stream
  Future<void> stopLiveLocationTracking() async {
    if (_positionSubscription != null) {
      await _positionSubscription!.cancel();
      _positionSubscription = null;
    }
    _isTracking = false;
    debugPrint('Live location tracking stopped.');
  }
}
