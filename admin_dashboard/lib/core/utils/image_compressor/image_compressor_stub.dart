import 'dart:typed_data';

/// Stub fallback implementation for platform-specific image compression.
Future<Uint8List> compressImagePlatform(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int maxHeight = 800,
  double quality = 0.8,
}) async {
  return inputBytes;
}
