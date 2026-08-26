import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmsService {
  static final SmsService instance = SmsService._();
  SmsService._();

  static const String _apiToken = '7012|ytbLSXpyeVUtvz8uFZA6KfiLFwc6NUa2opg7Q7bL0e04da3d';
  static const String _senderId = 'TextLKDemo';

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

  /// Sends SMS directly to Text.lk API and updates the Firestore document with results
  Future<void> sendOrderSms({
    required String orderDocId,
    required String customerPhone,
    required double totalAmount,
  }) async {
    final String? recipient = normalizeSriLankanPhone(customerPhone);
    final DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderDocId);

    if (recipient == null) {
      debugPrint('[SMS] Invalid or missing phone number for order: $orderDocId ($customerPhone)');
      await orderRef.update({
        'smsSent': false,
        'smsError': "Invalid or missing Sri Lankan phone number: '$customerPhone'",
      });
      return;
    }

    final String formattedTotal = totalAmount.toStringAsFixed(0);
    final String message =
        'Velora: Your order has been successfully placed. Order ID: $orderDocId. Amount: Rs.$formattedTotal. Thank you for shopping with us.';

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
          'smsSent': true,
          'smsSentAt': FieldValue.serverTimestamp(),
          'smsId': smsId,
          'smsError': FieldValue.delete(),
        });
        debugPrint('[SMS Success] Sent SMS for order $orderDocId to $recipient');
      } else {
        final String errorMsg = data['message'] ?? data['error'] ?? response.body;
        await orderRef.update({
          'smsSent': false,
          'smsError': errorMsg,
        });
        debugPrint('[SMS Error] Text.lk returned error for order $orderDocId: $errorMsg');
      }
    } catch (e) {
      debugPrint('[SMS Exception] Failed to send SMS for order $orderDocId: $e');
      await orderRef.update({
        'smsSent': false,
        'smsError': e.toString(),
      });
    }
  }
}
