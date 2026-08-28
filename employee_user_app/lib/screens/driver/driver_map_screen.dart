import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../services/driver_auth_service.dart';
import '../../services/driver_tracking_service.dart';
import '../../services/order_service.dart';
import '../../services/sms_service.dart';
import 'driver_delivery_detail_screen.dart';

class DriverMapScreen extends StatefulWidget {
  final OrderModel? order;

  const DriverMapScreen({
    super.key,
    this.order,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen>
    with TickerProviderStateMixin {
  // ── Google Map Controller ──────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final DriverTrackingService _trackingService = DriverTrackingService();

  // ── Map State ──────────────────────────────────────────────────────────────
  LatLng? _driverPosition = const LatLng(6.9271, 79.8612);
  LatLng? _customerDestination = const LatLng(6.8858, 79.8655);
  double _driverHeading = 45.0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isRouteLoading = false;
  bool _userHasPannedMap = false;
  bool _useInteractiveCanvas = false;
  String? _errorMessage;
  String? _distanceText;
  String? _durationText;

  // ── Marker Animation ───────────────────────────────────────────────────────
  AnimationController? _markerAnimCtrl;
  LatLng? _prevDriverPosition;

  // ── Initial Camera (Sri Lanka - Colombo default) ───────────────────────────
  static const LatLng _defaultPosition = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    // Default to interactive canvas if running on desktop Windows without web plugin
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      _useInteractiveCanvas = true;
    }

    _markerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateMarkers();
    _initializeTracking();
  }

  @override
  void dispose() {
    _trackingService.stopTracking(
      driverId: DriverAuthService.instance.driverId,
    );
    _markerAnimCtrl?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeTracking() async {
    // 1. Get customer destination from order address in background
    _resolveCustomerDestination().then((_) {
      if (mounted) {
        _updateMarkers();
        _fitBounds();
      }
    });

    // 2. Set up tracking callbacks
    _trackingService.onPositionUpdate = _onDriverPositionUpdate;
    _trackingService.onRouteUpdate = _onRouteUpdate;

    // 3. Start GPS tracking
    final driverId = DriverAuthService.instance.driverId;
    final orderId = widget.order?.id ?? '';

    await _trackingService.startTracking(
      orderId: orderId,
      driverId: driverId,
      customerDestination: _customerDestination,
    );

    if (mounted) {
      setState(() {
        if (_trackingService.currentDriverPosition != null) {
          _driverPosition = _trackingService.currentDriverPosition;
          _driverHeading = _trackingService.currentHeading;
        }
        _distanceText = _trackingService.routeDistanceText;
        _durationText = _trackingService.routeDurationText;
      });
      _updateMarkers();
      _updatePolylines();
      _fitBounds();
    }
  }

  Future<void> _resolveCustomerDestination() async {
    final address = widget.order?.deliveryAddress ?? '';
    if (address.isEmpty || address.toLowerCase().contains('pickup')) {
      return;
    }

    setState(() => _isRouteLoading = true);

    // Try geocoding the address
    final latLng = await DriverTrackingService.geocodeAddress(address);
    if (latLng != null) {
      _customerDestination = latLng;
    } else {
      debugPrint('[DriverMapScreen] Could not geocode "$address", using default');
      _customerDestination = const LatLng(6.8858, 79.8655);
    }

    if (mounted) setState(() => _isRouteLoading = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRACKING CALLBACKS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDriverPositionUpdate(LatLng newPosition) {
    if (!mounted) return;

    _prevDriverPosition = _driverPosition;
    setState(() {
      _driverPosition = newPosition;
      _driverHeading = _trackingService.currentHeading;
      _distanceText = _trackingService.routeDistanceText;
      _durationText = _trackingService.routeDurationText;
    });

    _animateDriverMarker();

    // Move camera to follow driver (only if user hasn't manually panned)
    if (!_userHasPannedMap && _mapController != null && !_useInteractiveCanvas) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 16.0,
              bearing: _driverHeading,
              tilt: 45.0,
            ),
          ),
        );
      } catch (e) {
        debugPrint('[DriverMapScreen] Camera animate error: $e');
      }
    }
  }

  void _onRouteUpdate() {
    if (!mounted) return;
    setState(() {
      _distanceText = _trackingService.routeDistanceText;
      _durationText = _trackingService.routeDurationText;
    });
    _updatePolylines();
    _updateMarkers();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKER & POLYLINE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateMarkers() {
    final markers = <Marker>{};

    // Driver marker with heading rotation
    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          rotation: _driverHeading,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Driver Location'),
          zIndexInt: 2,
        ),
      );
    }

    // Customer destination marker
    if (_customerDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerDestination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.order?.customerName ?? 'Customer',
            snippet: widget.order?.deliveryAddress ?? '',
          ),
          zIndexInt: 1,
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _updatePolylines() {
    if (_trackingService.routePolylinePoints.isEmpty) {
      setState(() => _polylines = {});
      return;
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _trackingService.routePolylinePoints,
          color: const Color(0xFF1B3E19),
          width: 5,
          patterns: [],
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    });
  }

  void _animateDriverMarker() {
    if (_prevDriverPosition == null || _driverPosition == null) {
      _updateMarkers();
      return;
    }

    _markerAnimCtrl?.reset();
    final animation = CurvedAnimation(
      parent: _markerAnimCtrl!,
      curve: Curves.easeInOut,
    );

    animation.addListener(() {
      if (!mounted) return;
      final t = animation.value;
      final interpolatedLat = _prevDriverPosition!.latitude +
          (_driverPosition!.latitude - _prevDriverPosition!.latitude) * t;
      final interpolatedLng = _prevDriverPosition!.longitude +
          (_driverPosition!.longitude - _prevDriverPosition!.longitude) * t;

      final markers = <Marker>{};
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(interpolatedLat, interpolatedLng),
          rotation: _driverHeading,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Driver Location'),
          zIndexInt: 2,
        ),
      );

      if (_customerDestination != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerDestination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: widget.order?.customerName ?? 'Customer',
              snippet: widget.order?.deliveryAddress ?? '',
            ),
            zIndexInt: 1,
          ),
        );
      }

      setState(() => _markers = markers);
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _updateMarkers();
      }
    });

    _markerAnimCtrl?.forward();
  }

  void _fitBounds() {
    if (_mapController == null || _useInteractiveCanvas) return;

    final points = <LatLng>[];
    if (_driverPosition != null) points.add(_driverPosition!);
    if (_customerDestination != null) points.add(_customerDestination!);

    try {
      if (points.length >= 2) {
        final bounds = DriverTrackingService.boundsFromLatLngs(points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } else if (points.length == 1) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: points.first, zoom: 15),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DriverMapScreen] Fit bounds error: $e');
    }
  }

  void _recenterOnDriver() {
    _userHasPannedMap = false;
    if (_driverPosition != null && _mapController != null && !_useInteractiveCanvas) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _driverPosition!,
              zoom: 16.0,
              bearing: _driverHeading,
              tilt: 45.0,
            ),
          ),
        );
      } catch (e) {
        debugPrint('[DriverMapScreen] Recenter error: $e');
      }
    }
  }

  Future<void> _callCustomer() async {
    final phone = widget.order?.customerPhone ?? '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP VIEW BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMapView() {
    if (_useInteractiveCanvas || (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)) {
      return _buildInteractiveCanvasMap();
    }

    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _driverPosition ?? _defaultPosition,
          zoom: 15.0,
          tilt: 45.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _fitBounds();
          _updatePolylines();
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onCameraMoveStarted: () {
          _userHasPannedMap = true;
        },
      );
    } catch (e) {
      debugPrint('[DriverMapScreen] GoogleMap render error: $e');
      return _buildInteractiveCanvasMap();
    }
  }

  Widget _buildInteractiveCanvasMap() {
    return Container(
      color: const Color(0xFFE8F0D8),
      child: Stack(
        children: [
          // Background Canvas Map with Roads and City Blocks
          CustomPaint(
            size: Size.infinite,
            painter: _DriverMapCanvasPainter(
              driverPos: _driverPosition ?? _defaultPosition,
              customerPos: _customerDestination ?? const LatLng(6.8858, 79.8655),
              routePoints: _trackingService.routePolylinePoints,
              heading: _driverHeading,
            ),
          ),

          // Customer Destination Marker
          if (_customerDestination != null)
            Align(
              alignment: const Alignment(0.6, -0.4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3E19),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.order?.customerName ?? 'Customer Destination',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

          // Driver Live Position Marker (Rotating Vehicle Icon based on Heading)
          Align(
            alignment: const Alignment(-0.2, 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: (_driverHeading * math.pi / 180.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3E19),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC8E635), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B3E19).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFFC8E635),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 12, color: Color(0xFF1B3E19)),
                      const SizedBox(width: 4),
                      Text(
                        'Driver (Heading: ${_driverHeading.toStringAsFixed(0)}°)',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B3E19),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final customerName = widget.order?.customerName ?? 'Customer';
    final deliveryAddress = widget.order?.deliveryAddress ?? 'Delivery Address';
    final orderDisplayId = widget.order?.displayId ?? 'Order';
    final customerPhone = widget.order?.customerPhone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Platform-Adaptive Map View ─────────────────────────────
            _buildMapView(),

            // ── Error Banner ───────────────────────────────────────────
            if (_errorMessage != null)
              Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Back Button (Top Left) ─────────────────────────────────
            if (Navigator.of(context).canPop())
              Positioned(
                left: 18,
                top: 18,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B3E19)),
                  ),
                ),
              ),

            // ── Map Action Buttons (Top Right) ─────────────────────────
            Positioned(
              right: 18,
              top: 18,
              child: Column(
                children: [
                  // Recenter Button
                  _MapActionButton(
                    icon: Icons.my_location_rounded,
                    onTap: _recenterOnDriver,
                  ),
                  const SizedBox(height: 10),
                  // Fit Bounds Button
                  _MapActionButton(
                    icon: Icons.crop_free_rounded,
                    onTap: _fitBounds,
                  ),
                  const SizedBox(height: 10),
                  // Toggle Map View Switcher Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _useInteractiveCanvas = !_useInteractiveCanvas;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useInteractiveCanvas ? Icons.map_rounded : Icons.dashboard_customize_rounded,
                            size: 16,
                            color: const Color(0xFF1B3E19),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _useInteractiveCanvas ? 'Google Map' : 'Canvas Map',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B3E19),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Top Navigation / ETA Pill ──────────────────────────────
            if (_distanceText != null || _durationText != null)
              Positioned(
                top: 18,
                left: 80,
                right: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3E19),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_rounded, color: Color(0xFFC8E635), size: 16),
                        const SizedBox(width: 6),
                        if (_distanceText != null)
                          Text(
                            _distanceText!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        if (_distanceText != null && _durationText != null)
                          Text(
                            '  •  ',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                          ),
                        if (_durationText != null)
                          Text(
                            _durationText!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC8E635),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Route Loading Indicator ────────────────────────────────
            if (_isRouteLoading)
              Positioned(
                top: 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1B3E19),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculating route...',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Bottom Navigation Card ─────────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F3),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Customer Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC8E635),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: Color(0xFF1B3E19), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B3E19),
                                ),
                              ),
                              Text(
                                customerPhone.isNotEmpty
                                    ? customerPhone
                                    : 'Contact available upon arrival',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (customerPhone.isNotEmpty)
                          InkWell(
                            onTap: _callCustomer,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1B3E19)),
                              ),
                              child: const Icon(Icons.phone_outlined,
                                  color: Color(0xFF1B3E19), size: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Address Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_outlined,
                              size: 16, color: Color(0xFF1B3E19)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deliveryAddress,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B3E19),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dispatch Header & Status Row
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.order?.branch ?? 'Courier Dispatch',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B3E19),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.notifications_none_rounded,
                            color: Color(0xFF1B3E19), size: 18),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons Bar (Issue & Arrived)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Issue reported to dispatch support.')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF1B3E19)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF1B3E19), size: 16),
                              label: Text(
                                'Issue',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B3E19),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                if (widget.order != null) {
                                  await OrderService.updateOrderStatus(
                                      widget.order!.id, 'Arrived');

                                  // Send SMS arrival notification to customer
                                  final phone = widget.order!.customerPhone;
                                  if (phone.isNotEmpty) {
                                    SmsService.instance.sendDriverArrivedSms(
                                      orderDocId: widget.order!.id,
                                      customerPhone: phone,
                                      customerName: widget.order!.customerName,
                                      driverName: DriverAuthService.instance.driverName,
                                    );
                                  }
                                }
                                if (!mounted) return;
                                nav.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DriverDeliveryDetailScreen(
                                      order: widget.order,
                                      orderId:
                                          widget.order?.id ?? 'ORD-0000',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B3E19),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16),
                              label: Text(
                                'Arrived',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Order & Distance Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          orderDisplayId,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _distanceText ?? (widget.order != null
                              ? '${widget.order!.items.length} items'
                              : '...'),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1B3E19),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Map Action Button Widget ─────────────────────────────────────────────────

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MapActionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1B3E19)),
      ),
    );
  }
}

// ── Driver Map Canvas Painter ────────────────────────────────────────────────

class _DriverMapCanvasPainter extends CustomPainter {
  final LatLng driverPos;
  final LatLng customerPos;
  final List<LatLng> routePoints;
  final double heading;

  _DriverMapCanvasPainter({
    required this.driverPos,
    required this.customerPos,
    required this.routePoints,
    required this.heading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Map background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F0D8),
    );

    final roadOutline = Paint()
      ..color = const Color(0xFFD0D8C0)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final blockPaint1 = Paint()..color = const Color(0xFFD0DCC0);
    final blockPaint2 = Paint()..color = const Color(0xFFC8D4B8);

    // City blocks
    final blocks = [
      Rect.fromLTWH(20, 40, size.width * 0.25, 70),
      Rect.fromLTWH(size.width * 0.35, 40, size.width * 0.25, 65),
      Rect.fromLTWH(size.width * 0.68, 40, size.width * 0.25, 75),
      Rect.fromLTWH(20, 145, size.width * 0.25, 80),
      Rect.fromLTWH(size.width * 0.35, 145, size.width * 0.25, 80),
      Rect.fromLTWH(size.width * 0.68, 145, size.width * 0.25, 80),
      Rect.fromLTWH(20, 260, size.width * 0.25, 90),
      Rect.fromLTWH(size.width * 0.35, 260, size.width * 0.25, 90),
      Rect.fromLTWH(size.width * 0.68, 260, size.width * 0.25, 90),
    ];

    for (var i = 0; i < blocks.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(blocks[i], const Radius.circular(8)),
        i.isEven ? blockPaint1 : blockPaint2,
      );
    }

    // Grid Roads
    final hRoads = [125.0, 240.0, 370.0];
    for (final y in hRoads) {
      if (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), roadOutline);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
      }
    }

    final vRoads = [size.width * 0.31, size.width * 0.64];
    for (final x in vRoads) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadOutline);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Road Route Polyline from Driver Position to Customer
    final startX = size.width * 0.40;
    final startY = size.height * 0.65;
    final endX = size.width * 0.80;
    final endY = size.height * 0.30;

    final routePath = Path()
      ..moveTo(startX, startY)
      ..lineTo(size.width * 0.64, startY)
      ..lineTo(size.width * 0.64, endY)
      ..lineTo(endX, endY);

    // Route Outer glow
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFF1B3E19)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Route Inner line
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFFC8E635)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DriverMapCanvasPainter oldDelegate) {
    return oldDelegate.driverPos != driverPos ||
        oldDelegate.customerPos != customerPos ||
        oldDelegate.heading != heading ||
        oldDelegate.routePoints != routePoints;
  }
}
