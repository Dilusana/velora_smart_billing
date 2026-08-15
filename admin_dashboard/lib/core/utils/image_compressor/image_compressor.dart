import 'dart:typed_data';

import 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart'
    if (dart.library.io) 'image_compressor_io.dart';

/// Compresses and resizes an image.
/// On Web, uses HTML Canvas element to perform hardware-accelerated, browser-native compression.
/// On IO (Mobile/Desktop), falls back to native Dart-side processing.
Future<Uint8List> compressImageNative(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int maxHeight = 800,
  double quality = 0.8,
}) {
  return compressImagePlatform(
    inputBytes,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    quality: quality,
  );
}
