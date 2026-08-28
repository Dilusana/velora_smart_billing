import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service for uploading images to Cloudinary via Unsigned Upload API.
class CloudinaryService {
  static const String cloudName = 'r0gfpzep';
  static const String uploadPreset = 'velora_billing';
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Uploads image bytes to Cloudinary using the unsigned preset [uploadPreset].
  /// Returns the returned `secure_url` on success.
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (onProgress != null) {
        onProgress(0.1);
      }

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = uploadPreset;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName.isNotEmpty ? fileName : 'upload.jpg',
      );
      request.files.add(multipartFile);

      if (onProgress != null) {
        onProgress(0.3);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Cloudinary upload timed out (45s). Check your internet connection.');
        },
      );

      if (onProgress != null) {
        onProgress(0.75);
      }

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = jsonMap['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          if (onProgress != null) {
            onProgress(1.0);
          }
          return secureUrl;
        }
        throw Exception('Cloudinary response did not contain a valid secure_url.');
      } else {
        String errorMessage = 'Cloudinary upload failed (HTTP ${response.statusCode})';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorJson.containsKey('error') && errorJson['error'] is Map) {
            errorMessage = errorJson['error']['message'] ?? errorMessage;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
