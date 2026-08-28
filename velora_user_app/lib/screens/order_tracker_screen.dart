import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/customer_tracking_service.dart';
import 'orders_screen.dart';
import 'order_receipt_screen.dart';

// ─── Order Tracker Screen ─────────────────────────────────────────────────────

class OrderTrackerScreen extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderTrackerScreen({super.key, this.order, this.orderId})
      : assert(order != null || orderId != null, 'Either order or orderId must be provided');

  String get effectiveOrderId => orderId ?? order!.id;

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

  List<_DeliveryStep> _getSteps(UserOrderModel? model, bool isPickup) {
    final statusStr = model?.status.toLowerCase() ?? widget.order?.status.name.toLowerCase() ?? 'processing';

    bool placedDone = true;
    bool preparedDone = statusStr.contains('prep') ||
        statusStr.contains('pack') ||
        statusStr.contains('confirm') ||
        statusStr.contains('ready') ||
        statusStr.contains('out') ||
        statusStr.contains('deliv') ||
        statusStr.contains('complet');

    bool outDone = statusStr.contains('out') ||
        statusStr.contains('ready') ||
        statusStr.contains('deliv') ||
        statusStr.contains('complet');

    bool deliveredDone = statusStr.contains('deliv') || statusStr.contains('complet');

    if (isPickup) {
      return [
        _DeliveryStep(
          label: 'Order Placed',
          sublabel: 'Your order was received',
          icon: Icons.shopping_bag_rounded,
          isDone: placedDone,
          isActive: !preparedDone,
        ),
        _DeliveryStep(
          label: 'Preparing Items',
          sublabel: 'Store staff is gathering your items',
          icon: Icons.inventory_2_rounded,
          isDone: preparedDone,
          isActive: preparedDone && !outDone,
        ),
        _DeliveryStep(
          label: 'Ready for Pickup',
          sublabel: 'Package is waiting at customer counter',
          icon: Icons.storefront_rounded,
          isDone: outDone,
          isActive: outDone && !deliveredDone,
        ),
        _DeliveryStep(
          label: 'Collected',
          sublabel: deliveredDone ? 'Picked up successfully!' : 'Awaiting customer pickup',
          icon: Icons.check_circle_rounded,
          isDone: deliveredDone,
          isActive: deliveredDone,
        ),
      ];
    }

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

    final isPickup = widget.order?.isPickup ?? false;
    if (!isPickup) {
      _initCustomerDestination(widget.order?.deliveryAddress ?? '');
      _startTrackingListener(widget.effectiveOrderId);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initCustomerDestination(String address) async {
    if (address.isNotEmpty) {
      final latLng = await CustomerTrackingService.geocodeAddress(address);
      if (latLng != null && mounted) {
        setState(() {
          _customerDestination = latLng;
        });
        _updateMapMarkersAndRoute(address);
      }
    }
  }

  void _startTrackingListener(String orderId) {
    CustomerTrackingService.getDriverTrackingStream(orderId).listen(
      (data) {
        if (!mounted) return;
        if (data != null && data.isActivelyTracking) {
          setState(() {
            _driverPosition = data.driverLatLng;
            _driverHeading = data.driverHeading;
            _hasActiveTracking = true;
          });
          _updateMapMarkersAndRoute(widget.order?.deliveryAddress ?? '');
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

  Future<void> _updateMapMarkersAndRoute([String deliveryAddress = '']) async {
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
            snippet: deliveryAddress.isNotEmpty ? deliveryAddress : widget.order?.deliveryAddress ?? '',
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
    final query = (widget.order?.deliveryAddress.isNotEmpty == true)
        ? widget.order!.deliveryAddress
        : 'Colombo, Sri Lanka';
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
    return StreamBuilder<UserOrderModel?>(
      stream: OrderRepository.instance.getOrderByIdStream(widget.effectiveOrderId),
      builder: (context, orderSnapshot) {
        final liveOrder = orderSnapshot.data;

        final isPickup = (liveOrder?.deliveryType ?? widget.order?.deliveryType ?? 'delivery').toLowerCase().contains('pickup') ||
            (liveOrder?.deliveryAddress ?? widget.order?.deliveryAddress ?? '').toLowerCase().contains('pickup');

        final String assignedName = (liveOrder?.driverName.isNotEmpty == true
                ? liveOrder!.driverName
                : (liveOrder?.employeeName.isNotEmpty == true
                    ? liveOrder!.employeeName
                    : (widget.order?.driverName.isNotEmpty == true
                        ? widget.order!.driverName
                        : widget.order?.employeeName ?? '')))
            .trim();

        final String assignedPhone = (liveOrder?.driverPhone.isNotEmpty == true
                ? liveOrder!.driverPhone
                : (widget.order?.driverPhone ?? ''))
            .trim();

        final String branchName = (liveOrder?.branch.isNotEmpty == true
                ? liveOrder!.branch
                : (widget.order?.branch ?? 'Main Store'))
            .trim();

        final double currentTotal = liveOrder != null ? liveOrder.total : (widget.order?.total ?? 0.0);
        final int currentItemCount = liveOrder != null ? liveOrder.items.fold(0, (s, i) => s + i.quantity) : (widget.order?.itemCount ?? 0);

        final statusStr = liveOrder?.status.toLowerCase() ?? widget.order?.status.name.toLowerCase() ?? 'processing';
        final isDelivered = statusStr.contains('deliv') || statusStr.contains('complet') || statusStr.contains('collect');

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
                                width: 36,
                                height: 36,
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
                              child: Text(
                                isPickup ? 'Order Pickup Details' : 'Track Order',
                                style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
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

                    // ── Header: Live Google Map (Delivery) OR Store Pickup Card (Pickup) ──
                    if (isPickup)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: const Color(0xFFCEE847).withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF5C8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF3A5A2A), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Store Pickup Order',
                                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                                        ),
                                        Text(
                                          'No delivery needed • Collect in-store',
                                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Self Pickup',
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF3A5A2A)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            branchName.isNotEmpty ? branchName : 'Velora Supermarket - Main Store',
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Store Hours: 8:00 AM – 10:00 PM',
                                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4B5563)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF3A5A2A)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Show Order #${widget.effectiveOrderId} at the pickup counter for quick collection.',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
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
                                top: 12,
                                left: 16,
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
                                top: 12,
                                right: 16,
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
                                bottom: 10,
                                left: 0,
                                right: 0,
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

                    // ── Employee / Courier Assignment Card ─────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_slideAnim),
                          child: FadeTransition(
                            opacity: _slideAnim,
                            child: _buildEmployeeHandlerCard(
                              isPickup: isPickup,
                              assignedName: assignedName,
                              assignedPhone: assignedPhone,
                              liveOrder: liveOrder,
                              context: context,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Delivery / Pickup Progress Tracker ──────────────────
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
                              Text(
                                isPickup ? 'Pickup Progress' : 'Delivery Progress',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                              ),
                              const SizedBox(height: 16),
                              Builder(builder: (context) {
                                final steps = _getSteps(liveOrder, isPickup);
                                return Column(
                                  children: steps
                                      .asMap()
                                      .entries
                                      .map((e) => _StepRow(step: e.value, isLast: e.key == steps.length - 1, pulseCtrl: _pulseCtrl))
                                      .toList(),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Receipt Button Card ────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
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
                                    isDelivered ? (isPickup ? 'Order Collected!' : 'Order Delivered!') : 'Order Summary & Receipt',
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
                                  isPickup
                                      ? 'Your order has been collected at the store counter. View the itemized receipt below.'
                                      : 'Your order has been delivered by courier ${assignedName.isNotEmpty ? assignedName : 'handler'}. View the itemized receipt below.',
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4B5563)),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final receiptOrder = widget.order ??
                                        Order(
                                          id: widget.effectiveOrderId,
                                          date: 'Just Now',
                                          status: isDelivered ? OrderStatus.completed : OrderStatus.processing,
                                          subtotal: currentTotal,
                                          paymentMethod: liveOrder?.paymentMethod ?? 'Card Payment',
                                          deliveryAddress: liveOrder?.deliveryAddress ?? 'Delivery',
                                          items: const [],
                                        );
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (ctx, anim, _) => OrderReceiptScreen(order: receiptOrder),
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
                      ),
                    ),

                    // ── Relevant Live Order Items Details ──────────────────
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
                                  Text(
                                    'Order #${widget.effectiveOrderId}',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFEEF5C8), borderRadius: BorderRadius.circular(10)),
                                    child: Text(
                                      '$currentItemCount Item${currentItemCount == 1 ? '' : 's'}',
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF3A5A2A)),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPickup ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isPickup ? 'In-Store Pickup' : 'Home Delivery',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isPickup ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (liveOrder != null && liveOrder.totalItemsCount > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: liveOrder.isAllPicked ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: liveOrder.isAllPicked ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        liveOrder.isAllPicked ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                                        size: 16,
                                        color: liveOrder.isAllPicked ? const Color(0xFF16A34A) : const Color(0xFF3A5A2A),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          liveOrder.isAllPicked
                                              ? 'All items picked by store employee (${liveOrder.pickedItemsCount}/${liveOrder.totalItemsCount})'
                                              : 'Item Picking: ${liveOrder.pickedItemsCount} of ${liveOrder.totalItemsCount} items picked',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: liveOrder.isAllPicked ? const Color(0xFF16A34A) : const Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (liveOrder != null && liveOrder.items.isNotEmpty)
                                ...liveOrder.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 42,
                                              height: 42,
                                              child: Builder(
                                                builder: (context) {
                                                  if (item.imageUrl.isNotEmpty) {
                                                    return _buildProductImage(
                                                      item.imageUrl,
                                                      item.isPicked ? Icons.check_circle_rounded : Icons.shopping_basket_rounded,
                                                    );
                                                  }
                                                  // Try resolving product image from ProductRepository stream/cache
                                                  return FutureBuilder<ProductModel?>(
                                                    future: item.productId.isNotEmpty
                                                        ? ProductRepository.instance.getProductById(item.productId)
                                                        : null,
                                                    builder: (context, prodSnap) {
                                                      final resolvedUrl = prodSnap.data?.imageUrl ?? '';
                                                      return _buildProductImage(
                                                        resolvedUrl,
                                                        item.isPicked ? Icons.check_circle_rounded : Icons.shopping_basket_rounded,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.productName,
                                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                                      ),
                                                    ),
                                                    if (item.isPicked)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFDCFCE7),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          'Picked',
                                                          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  '${item.quantity} x Rs ${item.price.toStringAsFixed(2)}',
                                                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rs ${item.total.toStringAsFixed(2)}',
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A1E)),
                                          ),
                                        ],
                                      ),
                                    ))
                              else if (widget.order != null)
                                ...widget.order!.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: _buildProductImage(item.imagePath, item.fallbackIcon),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                                ),
                                                Text(
                                                  item.unit,
                                                  style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'Rs ${item.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A1E)),
                                          ),
                                        ],
                                      ),
                                    )),
                              const Divider(color: Color(0xFFE5E7EB)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
                                  ),
                                  Text(
                                    'Rs ${currentTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827)),
                                  ),
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
      },
    );
  }

  Widget _buildEmployeeHandlerCard({
    required bool isPickup,
    required String assignedName,
    required String assignedPhone,
    UserOrderModel? liveOrder,
    required BuildContext context,
  }) {
    final hasAssigned = assignedName.trim().isNotEmpty && assignedName.toLowerCase() != 'null';

    final int pickedCount = liveOrder?.pickedItemsCount ?? 0;
    final int totalCount = liveOrder?.totalItemsCount ?? 0;
    final bool isAllPicked = liveOrder?.isAllPicked ?? false;

    if (!hasAssigned) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: const Icon(Icons.person_search_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickedCount > 0 ? 'Picking in progress ($pickedCount/$totalCount)' : 'Awaiting Employee Assignment',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPickup
                        ? 'Store staff is gathering your requested items.'
                        : 'Store staff is packing and preparing items for delivery.',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                pickedCount > 0 ? 'Picking' : 'Pending',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
              ),
            ),
          ],
        ),
      );
    }

    // Assigned Employee/Courier
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
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
                Text(
                  assignedName,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
                Text(
                  isPickup ? 'Store Order Handler' : 'Assigned Courier',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAllPicked ? const Color(0xFFDCFCE7) : const Color(0xFFEEF5C8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAllPicked
                            ? '✓ All Items Picked'
                            : (totalCount > 0 ? '✓ Picking ($pickedCount/$totalCount)' : '✓ Assigned Employee'),
                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contact actions
          Row(
            children: [
              _RoundIconBtn(
                icon: Icons.call_rounded,
                color: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () {
                  final phone = assignedPhone.isNotEmpty ? assignedPhone : '+94 77 123 4567';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling $assignedName ($phone)...', style: GoogleFonts.outfit(color: Colors.white)),
                      backgroundColor: const Color(0xFF3A5A2A),
                      behavior: SnackBarBehavior.floating,
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
                      content: Text('Messaging $assignedName...', style: GoogleFonts.outfit(color: Colors.white)),
                      backgroundColor: const Color(0xFF3A5A2A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(const Color(0xFF3A5A2A), const Color(0xFF5A8A3A), pulseCtrl.value),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3A5A2A).withValues(alpha: 0.3 + pulseCtrl.value * 0.2),
                            blurRadius: 10 + pulseCtrl.value * 5,
                          ),
                        ],
                      ),
                      child: Icon(step.icon, color: const Color(0xFFCEE847), size: 20),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
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
                width: 2,
                height: 32,
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
              Text(
                step.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: step.isDone || step.isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                ),
              ),
              Text(
                step.sublabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: step.isDone || step.isActive ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                ),
              ),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}



