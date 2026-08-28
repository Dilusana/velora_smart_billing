import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmsService {
  static final SmsService instance = SmsService._();
  SmsService._();

  static const String _apiToken = '7012|ytbLSXpyeVUtvz8uFZA6KfiLFwc6NUa2opg7Q7bL0e04da3d';
  static const String _senderId = 'VeloraSmart';

  /// Normalizes Sri Lankan phone numbers (e.g., "0771234567" -> "94771234567")
  String? normalizeSriLankanPhone(String phone) {
    if (phone.isEmpty) return null;
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;

    if (clean.startsWith('0')) {
      clean = '94${clean.substring(1)}';
    } else if (clean.startsWith('7')) {
      clean = '94$clean';
    }

    if (clean.startsWith('94') && clean.length >= 11) {
      return clean;
    }
    return clean.isNotEmpty ? clean : null;
  }

  /// Sends SMS notification to customer when order is ready / completed
  Future<bool> sendOrderCompletedSms({
    required String orderDocId,
    required String customerPhone,
    required String customerName,
    num? totalAmount,
    String? customMessage,
  }) async {
    final String? recipient = normalizeSriLankanPhone(customerPhone);
    final DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderDocId);

    if (recipient == null) {
      debugPrint('[SMS] Invalid or missing phone number for order: $orderDocId ($customerPhone)');
      try {
        await orderRef.update({
          'completionSmsSent': false,
          'completionSmsError': "Invalid or missing Sri Lankan phone number: '$customerPhone'",
        });
      } catch (_) {}
      return false;
    }

    final String nameGreeting = customerName.isNotEmpty && customerName != 'Customer' && customerName != 'Kiosk Customer'
        ? 'Dear $customerName, '
        : '';
    final String amountStr = totalAmount != null ? ' (Amount: Rs.${totalAmount.toStringAsFixed(0)})' : '';

    final String message = customMessage ??
        'Velora: ${nameGreeting}Your Order ID $orderDocId has been completed and is ready for pickup/delivery$amountStr. Thank you for shopping with us!';

    try {
      final response = await http.post(
        Uri.parse('https://app.text.lk/api/v3/sms/send'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'recipient': recipient,
          'sender_id': _senderId,
          'type': 'plain',
          'message': message,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('[SMS Response] HTTP ${response.statusCode}: $data');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (data['status'] == 'success' || data['code'] == 200 || data['data'] != null)) {
        final dynamic smsIdRaw = data['data'] != null ? (data['data']['id'] ?? data['data']['uid']) : null;
        final String smsId = smsIdRaw != null ? smsIdRaw.toString() : 'SENT_SUCCESS';

        await orderRef.update({
          'completionSmsSent': true,
          'completionSmsSentAt': FieldValue.serverTimestamp(),
          'completionSmsId': smsId,
          'completionSmsError': FieldValue.delete(),
        });
        debugPrint('[SMS Success] Sent completion SMS for order $orderDocId to $recipient');
        return true;
      } else {
        final String errorMsg = data['message'] ?? data['error'] ?? response.body;
        await orderRef.update({
          'completionSmsSent': false,
          'completionSmsError': errorMsg,
        });
        debugPrint('[SMS Error] Text.lk returned error for order $orderDocId: $errorMsg');
        return false;
      }
    } catch (e) {
      debugPrint('[SMS Exception] Failed to send completion SMS for order $orderDocId: $e');
      try {
        await orderRef.update({
          'completionSmsSent': false,
          'completionSmsError': e.toString(),
        });
      } catch (_) {}
      return false;
    }
  }

  /// Sends SMS notification to customer when driver has arrived at the delivery location
  Future<bool> sendDriverArrivedSms({
    required String orderDocId,
    required String customerPhone,
    required String customerName,
    String? driverName,
    String? customMessage,
  }) async {
    final String? recipient = normalizeSriLankanPhone(customerPhone);
    final DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderDocId);

    if (recipient == null) {
      debugPrint('[SMS] Invalid or missing phone number for driver arrival: $orderDocId ($customerPhone)');
      try {
        await orderRef.update({
          'arrivedSmsSent': false,
          'arrivedSmsError': "Invalid or missing Sri Lankan phone number: '$customerPhone'",
        });
      } catch (_) {}
      return false;
    }

    final String nameGreeting = customerName.isNotEmpty && customerName != 'Customer' && customerName != 'Kiosk Customer'
        ? 'Dear $customerName, '
        : '';
    final String driverInfo = (driverName != null && driverName.isNotEmpty) ? ' by driver $driverName' : '';

    final String message = customMessage ??
        'Velora: ${nameGreeting}Your delivery$driverInfo has arrived at your address (Order ID: $orderDocId). Please collect your package!';

    try {
      final response = await http.post(
        Uri.parse('https://app.text.lk/api/v3/sms/send'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'recipient': recipient,
          'sender_id': _senderId,
          'type': 'plain',
          'message': message,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('[SMS Arrived Response] HTTP ${response.statusCode}: $data');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (data['status'] == 'success' || data['code'] == 200 || data['data'] != null)) {
        final dynamic smsIdRaw = data['data'] != null ? (data['data']['id'] ?? data['data']['uid']) : null;
        final String smsId = smsIdRaw != null ? smsIdRaw.toString() : 'SENT_SUCCESS';

        await orderRef.update({
          'arrivedSmsSent': true,
          'arrivedSmsSentAt': FieldValue.serverTimestamp(),
          'arrivedSmsId': smsId,
          'arrivedSmsError': FieldValue.delete(),
        });
        debugPrint('[SMS Success] Sent arrival SMS for order $orderDocId to $recipient');
        return true;
      } else {
        final String errorMsg = data['message'] ?? data['error'] ?? response.body;
        await orderRef.update({
          'arrivedSmsSent': false,
          'arrivedSmsError': errorMsg,
        });
        debugPrint('[SMS Error] Text.lk returned error for arrival SMS $orderDocId: $errorMsg');
        return false;
      }
    } catch (e) {
      debugPrint('[SMS Exception] Failed to send arrival SMS for order $orderDocId: $e');
      try {
        await orderRef.update({
          'arrivedSmsSent': false,
          'arrivedSmsError': e.toString(),
        });
      } catch (_) {}
      return false;
    }
  }
}
