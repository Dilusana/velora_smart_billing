import 'package:flutter/foundation.dart';

/// Service to manage the current driver session / authenticated driver details
class DriverAuthService extends ChangeNotifier {
  static final DriverAuthService instance = DriverAuthService._internal();
  factory DriverAuthService() => instance;
  DriverAuthService._internal();

  String _driverId = 'CR-8942';
  String _driverName = 'Alex Mercer';
  String _driverPhone = '+1 (555) 234-5678';
  String _hubName = 'Kandy Central Hub';
  String _vehicleInfo = 'Van (V-401)';
  bool _isOnline = true;

  String get driverId => _driverId;
  String get driverName => _driverName;
  String get driverPhone => _driverPhone;
  String get hubName => _hubName;
  String get vehicleInfo => _vehicleInfo;
  bool get isOnline => _isOnline;

  void setDriverSession({
    required String driverId,
    String? driverName,
    String? driverPhone,
    String? hubName,
    String? vehicleInfo,
  }) {
    _driverId = driverId.trim();
    if (driverName != null && driverName.isNotEmpty) {
      _driverName = driverName;
    } else {
      // Auto-assign display name based on known demo IDs
      if (_driverId.toUpperCase().contains('1005')) {
        _driverName = 'EMP-1005 (Courier)';
      } else if (_driverId.toUpperCase().contains('8942')) {
        _driverName = 'Alex Mercer';
      } else {
        _driverName = 'Driver ${_driverId.toUpperCase()}';
      }
    }
    if (driverPhone != null) _driverPhone = driverPhone;
    if (hubName != null) _hubName = hubName;
    if (vehicleInfo != null) _vehicleInfo = vehicleInfo;
    notifyListeners();
  }

  void toggleOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }
}
