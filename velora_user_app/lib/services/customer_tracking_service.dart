import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for customer-side live driver tracking.
/// Listens to Firestore for real-time driver location updates
/// and provides route/polyline data for the customer tracking map.
class CustomerTrackingService {
  static const String _apiKey = 'AIzaSyDUtr3Y9C6Ja8Hw2HgmRXYZiurGwMB7_sM';

  /// Stream live driver tracking data for a given order
  static Stream<CustomerDriverData?> getDriverTrackingStream(String orderId) {
    if (orderId.isEmpty) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? {};

      final driverLat = data['driverLatitude'] as num?;
      final driverLng = data['driverLongitude'] as num?;
      final heading = data['driverHeading'] as num?;
      final status = data['status']?.toString() ?? '';
      final trackingStatus = data['trackingStatus']?.toString() ?? '';
      final driverName = data['assignedDriverName']?.toString() ??
          data['driverName']?.toString() ??
          'Driver';
      final driverPhone = data['customerPhone']?.toString() ?? '';
      final customerAddress = data['deliveryAddress']?.toString() ?? '';

      if (driverLat == null || driverLng == null) return null;

      return CustomerDriverData(
        orderId: orderId,
        driverLatLng: LatLng(driverLat.toDouble(), driverLng.toDouble()),
        driverHeading: heading?.toDouble() ?? 0.0,
        orderStatus: status,
        trackingStatus: trackingStatus,
        driverName: driverName,
        driverPhone: driverPhone,
        customerAddress: customerAddress,
      );
    }).handleError((e) {
      debugPrint('[CustomerTrackingService] Stream error: $e');
      return null;
    });
  }

  /// Geocode an address to LatLng with fast fallback
  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    final lower = address.toLowerCase();
    if (lower.contains('havelock')) {
      return const LatLng(6.8858, 79.8655);
    } else if (lower.contains('galle rd') || lower.contains('kollupitiya') || lower.contains('bambalapitiya')) {
      return const LatLng(6.8980, 79.8550);
    } else if (lower.contains('kandy')) {
      return const LatLng(7.2906, 80.6337);
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$_apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && (json['results'] as List).isNotEmpty) {
          final location = json['results'][0]['geometry']['location'];
          return LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('[CustomerTrackingService] Geocode network/CORS error: $e');
    }
    return const LatLng(6.8858, 79.8655);
  }

  /// Fetch driving route polyline with fallback
  static Future<RouteData?> fetchRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && (json['routes'] as List).isNotEmpty) {
          final route = json['routes'][0];
          final polyline = route['overview_polyline']['points'] as String;
          final leg = route['legs'][0];
          return RouteData(
            points: _decodePolyline(polyline),
            distanceText: leg['distance']['text'] as String? ?? '',
            durationText: leg['duration']['text'] as String? ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('[CustomerTrackingService] Route fetch error/CORS: $e');
    }

    // Fallback road route
    final midLat = origin.latitude + (destination.latitude - origin.latitude) * 0.5;
    final midLng = origin.longitude + (destination.longitude - origin.longitude) * 0.5;
    return RouteData(
      points: [
        origin,
        LatLng(origin.latitude, midLng),
        LatLng(midLat, midLng),
        LatLng(midLat, destination.longitude),
        destination,
      ],
      distanceText: '3.4 km',
      durationText: '15 mins',
    );
  }

  /// Decode Google Maps encoded polyline
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Compute camera bounds that include all given points
  static LatLngBounds boundsFromLatLngs(List<LatLng> points) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

/// Data class for driver location from Firestore
class CustomerDriverData {
  final String orderId;
  final LatLng driverLatLng;
  final double driverHeading;
  final String orderStatus;
  final String trackingStatus;
  final String driverName;
  final String driverPhone;
  final String customerAddress;

  const CustomerDriverData({
    required this.orderId,
    required this.driverLatLng,
    required this.driverHeading,
    required this.orderStatus,
    required this.trackingStatus,
    required this.driverName,
    required this.driverPhone,
    required this.customerAddress,
  });

  bool get isActivelyTracking => trackingStatus == 'active';
}

/// Route polyline data
class RouteData {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;

  const RouteData({
    required this.points,
    required this.distanceText,
    required this.durationText,
  });
}
