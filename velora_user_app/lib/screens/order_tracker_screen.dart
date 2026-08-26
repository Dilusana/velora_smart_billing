import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/order_repository.dart';
import '../models/order_model.dart';
import '../services/customer_tracking_service.dart';
import 'orders_screen.dart';
import 'order_receipt_screen.dart';

// ─── Order Tracker Screen ─────────────────────────────────────────────────────

class OrderTrackerScreen extends StatefulWidget {
  final Order order;
  const OrderTrackerScreen({super.key, required this.order});

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  // ── Live Tracking State ────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng? _driverPosition;
  LatLng? _customerDestination;
  double _driverHeading = 0.0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String? _etaText;
  String? _distText;
  bool _hasActiveTracking = false;

  List<_DeliveryStep> _getSteps(UserOrderModel? model) {
    final statusStr = model?.status.toLowerCase() ?? 'processing';

    bool placedDone = true;
    bool preparedDone = statusStr.contains('prep') || statusStr.contains('confirm') || statusStr.contains('out') || statusStr.contains('deliv') || statusStr.contains('complet');
    bool outDone = statusStr.contains('out') || statusStr.contains('deliv') || statusStr.contains('complet');
    bool deliveredDone = statusStr.contains('deliv') || statusStr.contains('complet');

    return [
      _DeliveryStep(
        label: 'Order Placed',
        sublabel: 'Your order was received',
        icon: Icons.shopping_bag_rounded,
        isDone: placedDone,
        isActive: !preparedDone,
      ),
      _DeliveryStep(
        label: 'Order Prepared',
        sublabel: 'Items are packed & ready',
        icon: Icons.inventory_2_rounded,
        isDone: preparedDone,
        isActive: preparedDone && !outDone,
      ),
      _DeliveryStep(
        label: 'Out for Delivery',
        sublabel: 'Courier is on the way',
        icon: Icons.delivery_dining_rounded,
        isDone: outDone,
        isActive: outDone && !deliveredDone,
      ),
      _DeliveryStep(
        label: 'Delivered',
        sublabel: deliveredDone ? 'Delivered successfully!' : 'Estimated: ~15 min',
        icon: Icons.home_rounded,
        isDone: deliveredDone,
        isActive: deliveredDone,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);

    // Initialize customer destination geocoding
    _initCustomerDestination();

    // Start listening for driver tracking data
    _startTrackingListener();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initCustomerDestination() async {
    final address = widget.order.deliveryAddress;
    if (address.isNotEmpty) {
      final latLng = await CustomerTrackingService.geocodeAddress(address);
      if (latLng != null && mounted) {
        setState(() {
          _customerDestination = latLng;
        });
        _updateMapMarkersAndRoute();
      }
    }
  }

  void _startTrackingListener() {
    CustomerTrackingService.getDriverTrackingStream(widget.order.id).listen(
      (data) {
        if (!mounted) return;
        if (data != null && data.isActivelyTracking) {
          setState(() {
            _driverPosition = data.driverLatLng;
            _driverHeading = data.driverHeading;
            _hasActiveTracking = true;
          });
          _updateMapMarkersAndRoute();
        } else {
          setState(() {
            _hasActiveTracking = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Tracking stream error: $e');
      },
    );
  }

  Future<void> _updateMapMarkersAndRoute() async {
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
          infoWindow: const InfoWindow(title: 'Your Driver'),
          zIndexInt: 2,
        ),
      );
    }

    // Customer destination marker
    if (_customerDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _customerDestination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: widget.order.deliveryAddress,
          ),
          zIndexInt: 1,
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);

    // Fetch route if both positions are available
    if (_driverPosition != null && _customerDestination != null) {
      final routeData = await CustomerTrackingService.fetchRoute(
        _driverPosition!,
        _customerDestination!,
      );
      if (routeData != null && mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routeData.points,
              color: const Color(0xFF3A5A2A),
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
          _etaText = routeData.durationText;
          _distText = routeData.distanceText;
        });
      }

      // Fit bounds to show both markers
      if (_mapController != null) {
        final bounds = CustomerTrackingService.boundsFromLatLngs([
          _driverPosition!,
          _customerDestination!,
        ]);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 60),
        );
      }
    }
  }

  Future<void> _launchGoogleMaps() async {
    final query = widget.order.deliveryAddress.isNotEmpty
        ? widget.order.deliveryAddress
        : '742 Evergreen Terrace, Springfield';
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Google Maps launch error: $e');
    }
  }

  Widget _buildProductImage(String? path, IconData fallbackIcon) {
    if (path == null || path.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF0F5D8),
        child: Center(child: Icon(fallbackIcon, size: 20, color: const Color(0xFF3A5A2A))),
      );
    }
    String formatted = path.trim();
    if (formatted.startsWith('assets/')) {
      formatted = formatted.replaceFirst('assets/', 'assests/');
    }
    final isNetwork = formatted.startsWith('http://') ||
        formatted.startsWith('https://') ||
        formatted.contains('cloudinary.com') ||
        formatted.contains('firebasestorage.googleapis.com');

    if (isNetwork) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF0F5D8),
          child: Center(child: Icon(fallbackIcon, size: 20, color: const Color(0xFF3A5A2A))),
        ),
      );
    } else {
      return Image.asset(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF0F5D8),
          child: Center(child: Icon(fallbackIcon, size: 20, color: const Color(0xFF3A5A2A))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 58,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF3A5A2A)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Track Order',
                            style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                        ),
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFFCEE847), Color(0xFF8DC63F)]),
                          ),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF1A2D5A), size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Live Google Maps Tracking View ─────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 260,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Stack(
                      children: [
                        // Google Map
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _customerDestination ?? _driverPosition ?? const LatLng(6.9271, 79.8612),
                              zoom: 14.0,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              // Fit bounds after map creation
                              if (_driverPosition != null && _customerDestination != null) {
                                final bounds = CustomerTrackingService.boundsFromLatLngs([
                                  _driverPosition!,
                                  _customerDestination!,
                                ]);
                                controller.animateCamera(
                                  CameraUpdate.newLatLngBounds(bounds, 60),
                                );
                              }
                            },
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                          ),
                        ),

                        // Status pill at top-left
                        Positioned(
                          top: 12, left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _hasActiveTracking ? const Color(0xFF3A5A2A) : const Color(0xFF6B7280),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasActiveTracking ? Icons.delivery_dining_rounded : Icons.schedule_rounded,
                                  color: _hasActiveTracking ? const Color(0xFFCEE847) : Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _hasActiveTracking ? 'Live Tracking' : 'Waiting for Driver',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Open Google Maps button at top-right
                        Positioned(
                          top: 12, right: 16,
                          child: GestureDetector(
                            onTap: _launchGoogleMaps,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text('Google Maps', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ETA & Distance badge at bottom-center
                        Positioned(
                          bottom: 10, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF3A5A2A)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _etaText != null
                                        ? 'Arriving in ~$_etaText'
                                        : (_distText != null ? '$_distText away' : 'Calculating...'),
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                  ),
                                  if (_distText != null && _etaText != null) ...[
                                    Text('  •  ', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
                                    Text(_distText!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A2A))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Courier Card ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_slideAnim),
                      child: FadeTransition(
                        opacity: _slideAnim,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFCEE847), Color(0xFF8DC63F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: const Color(0xFF3A5A2A), width: 2),
                                ),
                                child: const Icon(Icons.person_rounded, color: Color(0xFF1A2D5A), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Alan R.',
                                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                                    Text('Professional Courier',
                                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (i) =>
                                        Icon(i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                                          size: 13, color: const Color(0xFFFBBF24))),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              Row(
                                children: [
                                  _RoundIconBtn(
                                    icon: Icons.call_rounded,
                                    color: const Color(0xFFDCFCE7),
                                    iconColor: const Color(0xFF16A34A),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Calling courier Alan R. at +1 (555) 234-5678...', style: GoogleFonts.outfit(color: Colors.white)),
                                          backgroundColor: const Color(0xFF3A5A2A),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _RoundIconBtn(
                                    icon: Icons.chat_bubble_rounded,
                                    color: const Color(0xFFEEF5C8),
                                    iconColor: const Color(0xFF3A5A2A),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Messaging courier Alan R...', style: GoogleFonts.outfit(color: Colors.white)),
                                          backgroundColor: const Color(0xFF3A5A2A),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Delivery Progress ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery Progress',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                          const SizedBox(height: 16),
                          StreamBuilder<UserOrderModel?>(
                            stream: OrderRepository.instance.getOrderByIdStream(widget.order.id),
                            builder: (context, snapshot) {
                              final steps = _getSteps(snapshot.data);
                              return Column(
                                children: steps.asMap().entries.map((e) =>
                                  _StepRow(step: e.value, isLast: e.key == steps.length - 1, pulseCtrl: _pulseCtrl)).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Populated Post-Delivery View / Receipt Button ────────
                SliverToBoxAdapter(
                  child: StreamBuilder<UserOrderModel?>(
                    stream: OrderRepository.instance.getOrderByIdStream(widget.order.id),
                    builder: (context, snapshot) {
                      final status = snapshot.data?.status.toLowerCase() ?? 'processing';
                      final isDelivered = status.contains('deliv') || status.contains('complet');

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDelivered ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: isDelivered ? Border.all(color: const Color(0xFF86EFAC), width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDelivered ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                                    color: isDelivered ? const Color(0xFF16A34A) : const Color(0xFF3A5A2A),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDelivered ? 'Order Delivered!' : 'Order Summary & Receipt',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDelivered ? const Color(0xFF15803D) : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              if (isDelivered) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Your order has been delivered by courier Alan R. You can view the itemized receipt below.',
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4B5563)),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (ctx, anim, _) => OrderReceiptScreen(order: widget.order),
                                        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
                                          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3A5A2A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                  label: Text(
                                    'View Official Order Receipt',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Order Items Details Summary ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Order #${widget.order.id}',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFEEF5C8), borderRadius: BorderRadius.circular(10)),
                                child: Text('${widget.order.itemCount} Items',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF3A5A2A))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...widget.order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40, height: 40,
                                    child: _buildProductImage(item.imagePath, item.fallbackIcon),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                                      Text(item.unit,
                                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF))),
                                    ],
                                  ),
                                ),
                                Text('Rs ${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A1E))),
                              ],
                            ),
                          )),
                          const Divider(color: Color(0xFFE5E7EB)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
                              Text('Rs ${widget.order.total.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),


          ],
        ),
      ),
    );
  }
}



// ─── Delivery Step Model ──────────────────────────────────────────────────────

class _DeliveryStep {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  const _DeliveryStep({
    required this.label,
    required this.sublabel,
    required this.icon,
    this.isDone = false,
    this.isActive = false,
  });
}

// ─── Step Row ─────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final _DeliveryStep step;
  final bool isLast;
  final AnimationController pulseCtrl;

  const _StepRow({required this.step, required this.isLast, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            step.isActive
                ? AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (ctx, _) => Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(const Color(0xFF3A5A2A), const Color(0xFF5A8A3A), pulseCtrl.value),
                        boxShadow: [BoxShadow(color: const Color(0xFF3A5A2A).withValues(alpha: 0.3 + pulseCtrl.value * 0.2), blurRadius: 10 + pulseCtrl.value * 5)],
                      ),
                      child: Icon(step.icon, color: const Color(0xFFCEE847), size: 20),
                    ),
                  )
                : Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isDone ? const Color(0xFF3A5A2A) : const Color(0xFFF3F4F6),
                      border: step.isDone ? null : Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                    ),
                    child: step.isDone
                        ? const Icon(Icons.check_rounded, color: Color(0xFFCEE847), size: 20)
                        : Icon(step.icon, color: const Color(0xFFD1D5DB), size: 18),
                  ),

            if (!isLast)
              Container(
                width: 2, height: 32,
                decoration: BoxDecoration(
                  color: step.isDone ? const Color(0xFF3A5A2A) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),

        const SizedBox(width: 14),

        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: step.isDone || step.isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                )),
              Text(step.sublabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: step.isDone || step.isActive ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                )),
              if (!isLast) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Round Icon Button ────────────────────────────────────────────────────────

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundIconBtn({required this.icon, required this.color, required this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}



