import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/delivery_order_model.dart';
import '../services/driver_location_service.dart';
import '../services/delivery_tracking_service.dart';

class DriverActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  const DriverActiveDeliveryScreen({super.key, required this.orderId});

  @override
  State<DriverActiveDeliveryScreen> createState() => _DriverActiveDeliveryScreenState();
}

class _DriverActiveDeliveryScreenState extends State<DriverActiveDeliveryScreen> {
  bool _isTracking = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seedSampleOrderIfMissing();
  }

  Future<void> _seedSampleOrderIfMissing() async {
    final existing = await DeliveryTrackingService.instance.getOrder(widget.orderId);
    if (existing == null) {
      final sample = DeliveryOrderModel(
        orderId: widget.orderId,
        customerId: 'customer_101',
        driverId: 'driver_202',
        driverName: 'Alan R. (Courier)',
        driverPhone: '+1 (555) 234-5678',
        customerAddress: '742 Evergreen Terrace, Springfield',
        customerLatitude: 37.7749,
        customerLongitude: -122.4194,
        driverLatitude: 37.7790,
        driverLongitude: -122.4140,
        status: 'out_for_delivery',
      );
      await DeliveryTrackingService.instance.createOrSeedSampleOrder(sample);
    }
  }

  Future<void> _toggleTracking(DeliveryOrderModel order) async {
    setState(() => _isLoading = true);

    if (_isTracking) {
      await DriverLocationService.instance.stopLiveLocationTracking();
      setState(() {
        _isTracking = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Live GPS location tracking stopped.', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
      }
    } else {
      final success = await DriverLocationService.instance.startLiveLocationTracking(order.orderId);
      setState(() {
        _isTracking = success;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Live GPS location tracking active!'
                  : 'Failed to access GPS location or permissions denied.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(DeliveryOrderModel order, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await DriverLocationService.instance.updateOrderStatus(orderId: order.orderId, status: newStatus);

      if (newStatus == 'delivered') {
        setState(() => _isTracking = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to: ${newStatus.toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFF3A5A2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Driver Dashboard',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DeliveryOrderModel?>(
        stream: DeliveryTrackingService.instance.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3A5A2A)));
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order document loading...'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF5C8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF3A5A2A), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.driverName,
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                            ),
                            Text(
                              'Active Order: #${order.orderId}',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location Tracking Control Box
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE GPS LOCATION BROADCAST',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            _isTracking ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                            color: _isTracking ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTracking ? 'GPS Broadcasting Active' : 'GPS Tracking Stopped',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isTracking ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isTracking,
                            activeThumbColor: const Color(0xFF3A5A2A),
                            onChanged: order.isDelivered ? null : (_) => _toggleTracking(order),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Live Coordinates: Lat ${order.driverLatitude.toStringAsFixed(4)}, Lng ${order.driverLongitude.toStringAsFixed(4)}',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order Status Controller
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPDATE DELIVERY STATUS',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusBtn(order, 'preparing', '🧑‍🍳 Preparing Order'),
                      const SizedBox(height: 8),
                      _buildStatusBtn(order, 'assigned', '🛵 Driver Assigned'),
                      const SizedBox(height: 8),
                      _buildStatusBtn(order, 'out_for_delivery', '⚡ Out for Delivery'),
                      const SizedBox(height: 8),
                      _buildStatusBtn(order, 'delivered', '🎉 Complete Delivery'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBtn(DeliveryOrderModel order, String statusKey, String label) {
    final isActive = order.status == statusKey;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _updateStatus(order, statusKey),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF3A5A2A) : Colors.transparent,
          side: BorderSide(
            color: isActive ? const Color(0xFF3A5A2A) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
