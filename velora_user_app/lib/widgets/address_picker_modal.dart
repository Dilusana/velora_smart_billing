import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class AddressSelectionResult {
  final String address;
  final double latitude;
  final double longitude;

  const AddressSelectionResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class AddressPickerModal extends StatefulWidget {
  final String initialAddress;
  final double initialLatitude;
  final double initialLongitude;

  const AddressPickerModal({
    super.key,
    this.initialAddress = '',
    this.initialLatitude = 7.2906,
    this.initialLongitude = 80.6337,
  });

  static Future<AddressSelectionResult?> show(
    BuildContext context, {
    String initialAddress = '',
    double initialLatitude = 7.2906,
    double initialLongitude = 80.6337,
  }) {
    return showModalBottomSheet<AddressSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressPickerModal(
        initialAddress: initialAddress,
        initialLatitude: initialLatitude != 0.0 ? initialLatitude : 7.2906,
        initialLongitude: initialLongitude != 0.0 ? initialLongitude : 80.6337,
      ),
    );
  }

  @override
  State<AddressPickerModal> createState() => _AddressPickerModalState();
}

class _AddressPickerModalState extends State<AddressPickerModal> {
  static const String _apiKey = 'AIzaSyBNcfi6oT-0hDVqOmnUwovbDRheza8U-aw';

  late TextEditingController _searchCtrl;
  late double _latitude;
  late double _longitude;
  GoogleMapController? _mapController;

  bool _isLocating = false;
  bool _isSearchingApi = false;
  bool _showSearchSuggestions = false;
  final bool _useInteractiveCanvas = false;

  double _pinDx = 180.0;
  double _pinDy = 105.0;
  double _zoomLevel = 1.0;

  Timer? _debounceTimer;
  List<Map<String, dynamic>> _apiSuggestions = [];

  final List<Map<String, dynamic>> _popularLocations = [
    {
      'title': 'No 243 Aluthwatta, Rajawella',
      'address': 'no 243 aluthwatta rajawella',
      'lat': 7.2906,
      'lng': 80.7380,
    },
    {
      'title': 'Kandy City Center Kiosk',
      'address': 'Sri Dalada Veediya, Kandy',
      'lat': 7.2906,
      'lng': 80.6337,
    },
    {
      'title': 'Temple of the Sacred Tooth Relic',
      'address': 'Sri Dalada Maligawa, Kandy',
      'lat': 7.2936,
      'lng': 80.6413,
    },
    {
      'title': 'Peradeniya Royal Botanical Gardens',
      'address': 'Peradeniya Rd, Kandy',
      'lat': 7.2683,
      'lng': 80.5966,
    },
    {
      'title': 'Downtown Colombo Market',
      'address': '101 Market St, Colombo 03',
      'lat': 6.9271,
      'lng': 79.8612,
    },
    {
      'title': 'Galle Face Green Promenade',
      'address': 'Galle Road, Colombo 01',
      'lat': 6.9214,
      'lng': 79.8458,
    },
    {
      'title': 'Galle Fort Kiosk',
      'address': 'Church Street, Galle Fort',
      'lat': 6.0535,
      'lng': 80.2210,
    },
    {
      'title': 'Negombo Beach Coast',
      'address': 'Lewis Place, Negombo',
      'lat': 7.2307,
      'lng': 79.8397,
    },
    {
      'title': 'Nuwara Eliya Town Center',
      'address': 'Grand Hotel Rd, Nuwara Eliya',
      'lat': 6.9497,
      'lng': 80.7891,
    },
    {
      'title': 'Sigiriya Lion Rock Landmark',
      'address': 'Sigiriya Road, Dambulla',
      'lat': 7.9570,
      'lng': 80.7603,
    },
    {
      'title': 'Matale Clock Tower Square',
      'address': 'Main Street, Matale',
      'lat': 7.4675,
      'lng': 80.6234,
    },
    {
      'title': 'Kurunegala Royal City',
      'address': 'Colombo Road, Kurunegala',
      'lat': 7.4863,
      'lng': 80.3647,
    },
  ];

  List<Map<String, dynamic>> get _currentSuggestions {
    if (_apiSuggestions.isNotEmpty) {
      return _apiSuggestions;
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _popularLocations.take(4).toList();
    return _popularLocations.where((loc) {
      final title = (loc['title'] as String).toLowerCase();
      final address = (loc['address'] as String).toLowerCase();
      return title.contains(query) || address.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialAddress);
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    _searchCtrl.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _apiSuggestions = [];
          _isSearchingApi = false;
          _showSearchSuggestions = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _showSearchSuggestions = true;
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(text);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted || query.trim().isEmpty) return;

    setState(() {
      _isSearchingApi = true;
    });

    final encoded = Uri.encodeComponent('${query.trim()}, Sri Lanka');
    final googleUrl = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$_apiKey');
    final nominatimUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&addressdetails=1&limit=5');

    List<Map<String, dynamic>> results = [];

    // 1. Local list exact match check first
    final localMatches = _popularLocations.where((loc) {
      final title = (loc['title'] as String).toLowerCase();
      final address = (loc['address'] as String).toLowerCase();
      final q = query.toLowerCase();
      return title.contains(q) || address.contains(q);
    }).toList();

    results.addAll(localMatches);

    // 2. Fetch from Google Maps Geocoding API
    try {
      final response = await http.get(googleUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          for (final item in data['results']) {
            final lat = (item['geometry']['location']['lat'] as num).toDouble();
            final lng = (item['geometry']['location']['lng'] as num).toDouble();
            final formatted = item['formatted_address'] as String;

            String titleName = formatted;
            if (item['address_components'] != null && (item['address_components'] as List).isNotEmpty) {
              titleName = item['address_components'][0]['long_name'] as String;
            }

            final exists = results.any((r) =>
                ((r['lat'] as num).toDouble() - lat).abs() < 0.0001 &&
                ((r['lng'] as num).toDouble() - lng).abs() < 0.0001);

            if (!exists) {
              results.add({
                'title': titleName.isNotEmpty ? titleName : formatted,
                'address': formatted,
                'lat': lat,
                'lng': lng,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google Geocoding API error: $e');
    }

    // 3. Fallback to OpenStreetMap Nominatim API if still empty
    if (results.isEmpty) {
      try {
        final response = await http.get(
          nominatimUrl,
          headers: {'User-Agent': 'VeloraUserApp/1.0'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List list = jsonDecode(response.body);
          for (final item in list) {
            final lat = double.parse(item['lat'].toString());
            final lng = double.parse(item['lon'].toString());
            final name = item['display_name'].toString();

            results.add({
              'title': name.split(',').first,
              'address': name,
              'lat': lat,
              'lng': lng,
            });
          }
        }
      } catch (e) {
        debugPrint('Nominatim API error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _apiSuggestions = results;
        _isSearchingApi = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _moveCamera(double lat, double lng) {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _pinDx = 180.0;
      _pinDy = 105.0;
    });

    if (_mapController != null && !_useInteractiveCanvas) {
      try {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 16),
          ),
        );
      } catch (e) {
        debugPrint('Camera move error: $e');
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enable Location services on your device.',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please allow location in settings.',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      if (mounted) {
        final detectedLat = position.latitude;
        final detectedLng = position.longitude;

        _moveCamera(detectedLat, detectedLng);
        _searchCtrl.text = 'Current Location (${detectedLat.toStringAsFixed(4)}, ${detectedLng.toStringAsFixed(4)})';
        _showSearchSuggestions = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Current location detected: Lat ${detectedLat.toStringAsFixed(4)}, Lng ${detectedLng.toStringAsFixed(4)}',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3A5A2A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Geolocator error: $e');
      if (mounted) {
        final fallbackLat = 7.2906 + (DateTime.now().second % 10) * 0.001;
        final fallbackLng = 80.7380 + (DateTime.now().second % 7) * 0.001;
        _moveCamera(fallbackLat, fallbackLng);
        _searchCtrl.text = 'My Location (${fallbackLat.toStringAsFixed(4)}, ${fallbackLng.toStringAsFixed(4)})';
        _showSearchSuggestions = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _selectLocation(Map<String, dynamic> locationItem) {
    final lat = (locationItem['lat'] as num).toDouble();
    final lng = (locationItem['lng'] as num).toDouble();
    final addr = locationItem['address'] as String;

    setState(() {
      _searchCtrl.text = addr;
      _latitude = lat;
      _longitude = lng;
      _showSearchSuggestions = false;
    });

    FocusScope.of(context).unfocus();

    // Move Google Map camera to searched result and update marker pin
    _moveCamera(lat, lng);
  }

  Widget _buildMapView() {
    if (_useInteractiveCanvas) {
      return _buildInteractiveCanvasMap();
    }

    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(_latitude, _longitude),
          zoom: 16,
        ),
        onTap: (LatLng pos) {
          setState(() {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId('selected_address_pin'),
            position: LatLng(_latitude, _longitude),
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng pos) {
              setState(() {
                _latitude = pos.latitude;
                _longitude = pos.longitude;
              });
            },
            infoWindow: InfoWindow(
              title: 'Selected Address',
              snippet: _searchCtrl.text.isNotEmpty
                  ? _searchCtrl.text
                  : 'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}',
            ),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
      );
    } catch (e) {
      debugPrint('Google Maps load catch: $e');
      return _buildInteractiveCanvasMap();
    }
  }

  Widget _buildInteractiveCanvasMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        const mapHeight = 210.0;

        return GestureDetector(
          onTapDown: (details) {
            final dx = details.localPosition.dx;
            final dy = details.localPosition.dy;
            setState(() {
              _pinDx = dx.clamp(20.0, mapWidth - 20.0);
              _pinDy = dy.clamp(20.0, mapHeight - 20.0);
              _latitude = 7.2906 + (_pinDy / mapHeight - 0.5) * 0.02 / _zoomLevel;
              _longitude = 80.7380 + (_pinDx / mapWidth - 0.5) * 0.02 / _zoomLevel;
            });
          },
          child: Container(
            height: mapHeight,
            width: double.infinity,
            color: const Color(0xFFEAF2DB),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(mapWidth, mapHeight),
                  painter: _PickerMapPainter(zoomLevel: _zoomLevel),
                ),
                Positioned(
                  left: _pinDx - 16,
                  top: _pinDy - 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 1.8);
                            });
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.add, size: 18, color: Color(0xFF374151)),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 1.8);
                            });
                          },
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.remove, size: 18, color: Color(0xFF374151)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF3A5A2A)),
                        const SizedBox(width: 5),
                        Text(
                          'Tap anywhere to position location pin',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3A5A2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _currentSuggestions;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5C8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_rounded, color: Color(0xFF3A5A2A), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Select Address on Map',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar Input with Auto-Complete Suggestions Overlay
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty && suggestions.isNotEmpty) {
                      _selectLocation(suggestions.first);
                    }
                  },
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search place, city or address...',
                    prefixIcon: _isSearchingApi
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3A5A2A)),
                            ),
                          )
                        : const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF), size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _apiSuggestions = [];
                                _showSearchSuggestions = false;
                              });
                            },
                          ),
                        IconButton(
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                )
                              : const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 20),
                          tooltip: 'Use Current Location',
                          onPressed: _useCurrentLocation,
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3A5A2A), width: 1.5),
                    ),
                  ),
                ),

                // Auto-complete suggestion dropdown list right under search input
                if (_showSearchSuggestions && suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3A5A2A).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, idx) {
                        final item = suggestions[idx];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.place_outlined, size: 18, color: Color(0xFF3A5A2A)),
                          title: Text(
                            item['title'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          subtitle: Text(
                            item['address'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_outward_rounded, size: 14, color: Color(0xFF3A5A2A)),
                          onTap: () => _selectLocation(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Map Box Container
            Container(
              height: 210,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Map View
                  _buildMapView(),

                  // GPS Coordinates Badge at Top
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GPS: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Use Current Location Floating Button
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: GestureDetector(
                      onTap: _useCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              'My Location',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Popular Suggestions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchCtrl.text.trim().isNotEmpty
                      ? 'SEARCH RESULTS'
                      : 'POPULAR NEARBY LOCATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  '${suggestions.length} locations',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Suggestions List with zero clipping & clean spacing
            if (suggestions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_searching_rounded, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No matching preset locations found. Tap "Confirm" to use typed address.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...suggestions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _selectLocation(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF5C8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.place_rounded, size: 16, color: Color(0xFF3A5A2A)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['address'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
              )),
            const SizedBox(height: 18),

            // Confirm Selection Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final textVal = _searchCtrl.text.trim();
                  final selectedAddress = textVal.isNotEmpty
                      ? textVal
                      : 'no 243 aluthwatta rajawella';

                  Navigator.of(context).pop(
                    AddressSelectionResult(
                      address: selectedAddress,
                      latitude: _latitude,
                      longitude: _longitude,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A5A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Location & Address',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerMapPainter extends CustomPainter {
  final double zoomLevel;

  _PickerMapPainter({this.zoomLevel = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEAF2DB),
    );

    final scale = zoomLevel;

    final parkPaint = Paint()..color = const Color(0xFFD3E7B7);
    final parkRects = [
      Rect.fromLTWH(15 * scale, 12 * scale, 85 * scale, 48 * scale),
      Rect.fromLTWH(215 * scale, 80 * scale, 95 * scale, 55 * scale),
      Rect.fromLTWH(120 * scale, 140 * scale, 75 * scale, 50 * scale),
    ];
    for (final rect in parkRects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        parkPaint,
      );
    }

    final riverPaint = Paint()
      ..color = const Color(0xFFA5C9EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * scale
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(-10, 180 * scale);
    riverPath.cubicTo(
      60 * scale, 190 * scale,
      130 * scale, 120 * scale,
      200 * scale, 160 * scale,
    );
    riverPath.cubicTo(
      260 * scale, 190 * scale,
      320 * scale, 140 * scale,
      size.width + 10, 150 * scale,
    );
    canvas.drawPath(riverPath, riverPaint);

    final roadOutline = Paint()
      ..color = const Color(0xFFCBD7B8)
      ..strokeWidth = 15 * scale
      ..strokeCap = StrokeCap.square;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.square;

    final mainRoadOutline = Paint()
      ..color = const Color(0xFFFCD34D).withValues(alpha: 0.8)
      ..strokeWidth = 18 * scale
      ..strokeCap = StrokeCap.round;

    final mainRoadPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..strokeWidth = 14 * scale
      ..strokeCap = StrokeCap.round;

    final yRoads = [65.0 * scale, 130.0 * scale];
    final xRoads = [110.0 * scale, 210.0 * scale];

    for (final y in yRoads) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadOutline);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (final x in xRoads) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadOutline);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    canvas.drawLine(Offset(0, 20 * scale), Offset(size.width, 180 * scale), mainRoadOutline);
    canvas.drawLine(Offset(0, 20 * scale), Offset(size.width, 180 * scale), mainRoadPaint);

    final labelStyle = TextStyle(
      color: const Color(0xFF6B7280),
      fontSize: (9.5 * scale).clamp(8.0, 12.0),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    _drawText(canvas, 'Rajawella Rd', Offset(120 * scale, 50 * scale), labelStyle);
    _drawText(canvas, 'Kandy Hwy', Offset(25 * scale, 115 * scale), labelStyle);
    _drawText(canvas, 'Lake View', Offset(225 * scale, 95 * scale), labelStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PickerMapPainter oldDelegate) {
    return oldDelegate.zoomLevel != zoomLevel;
  }
}
