import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_order_model.dart';
import '../services/delivery_tracking_service.dart';

class CustomerLiveTrackingScreen extends StatefulWidget {
  final String orderId;
  const CustomerLiveTrackingScreen({super.key, required this.orderId});

  @override
  State<CustomerLiveTrackingScreen> createState() => _CustomerLiveTrackingScreenState();
}

class _CustomerLiveTrackingScreenState extends State<CustomerLiveTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _customerIcon;
  bool _isMapCreated = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
  }

  Future<void> _loadCustomMarkerIcons() async {
    _driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _customerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    if (mounted) setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapCreated = true;
  }

  void _updateMapMarkersAndCamera(DeliveryOrderModel order) {
    final customerLatLng = LatLng(order.customerLatitude, order.customerLongitude);
    final driverLatLng = LatLng(order.driverLatitude, order.driverLongitude);

    final Set<Marker> updatedMarkers = {
      // Customer Marker
      Marker(
        markerId: const MarkerId('customer_location'),
        position: customerLatLng,
        icon: _customerIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Delivery Address', snippet: 'Your Location'),
      ),
      // Driver Live Marker
      Marker(
        markerId: const MarkerId('driver_location'),
        position: driverLatLng,
        icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: order.driverName,
          snippet: 'Status: ${order.status.replaceAll('_', ' ').toUpperCase()}',
        ),
      ),
    };

    // Polyline connecting Driver -> Customer
    final Set<Polyline> updatedPolylines = {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: [driverLatLng, customerLatLng],
        color: const Color(0xFF3A5A2A),
        width: 5,
      ),
    };

    setState(() {
      _markers.clear();
      _markers.addAll(updatedMarkers);
      _polylines.clear();
      _polylines.addAll(updatedPolylines);
    });

    // Auto-fit bounds containing both Customer & Driver
    if (_mapController != null && _isMapCreated) {
      _fitMapCameraBounds(driverLatLng, customerLatLng);
    }
  }

  void _fitMapCameraBounds(LatLng p1, LatLng p2) {
    final southWest = LatLng(
      p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
    );
    final northEast = LatLng(
      p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
    );

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'preparing':
        return const Color(0xFFD97706);
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'out_for_delivery':
        return const Color(0xFF16A34A);
      case 'delivered':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF3A5A2A);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'preparing':
        return '🧑‍🍳 Order Preparing';
      case 'assigned':
        return '🛵 Driver Assigned';
      case 'out_for_delivery':
        return '⚡ Out for Delivery';
      case 'delivered':
        return '🎉 Order Delivered!';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3A5A2A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Live Delivery Tracker',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DeliveryOrderModel?>(
        stream: DeliveryTrackingService.instance.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3A5A2A)),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 12),
                    Text(
                      'Order details not found.',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order ID: ${widget.orderId}',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Trigger map update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMapMarkersAndCamera(order);
          });

          return Stack(
            children: [
              // ── Google Maps View ────────────────────────────────────
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(order.driverLatitude, order.driverLongitude),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
              ),

              // ── Top Order Status Pill ────────────────────────────────
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Order #${order.orderId}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Driver Card ─────────────────────────────────
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF5C8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF3A5A2A), size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.driverName,
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                                ),
                                Text(
                                  'Delivery Courier • Assigned Driver',
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                              child: const Icon(Icons.call_rounded, color: Color(0xFF16A34A), size: 20),
                            ),
                            onPressed: () => _launchPhoneCall(order.driverPhone),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 16, color: Color(0xFF3A5A2A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.customerAddress.isNotEmpty ? order.customerAddress : 'Customer Delivery Address',
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF374151)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
