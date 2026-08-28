import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Non-web platform image compression using Dart `image` package.
Future<Uint8List> compressImagePlatform(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int maxHeight = 800,
  double quality = 0.8,
}) async {
  try {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    img.Image resized = decoded;
    if (decoded.width > maxWidth || decoded.height > maxHeight) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxWidth : null,
        height: decoded.height > decoded.width ? maxHeight : null,
      );
    }

    final jpegQuality = (quality * 100).round().clamp(1, 100);
    final jpgBytes = img.encodeJpg(resized, quality: jpegQuality);
    return Uint8List.fromList(jpgBytes);
  } catch (_) {
    return inputBytes;
  }
}
