// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Browser-native HTML Canvas resizing and JPEG compression.
/// Executes in the browser's native GPU/rendering pipeline, bypassing slow Dart-side pixel loops.
Future<Uint8List> compressImagePlatform(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int maxHeight = 800,
  double quality = 0.8,
}) async {
  try {
    final blob = html.Blob([inputBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final completer = Completer<Uint8List>();
    final image = html.ImageElement();

    image.onLoad.listen((_) {
      try {
        int width = image.width ?? 0;
        int height = image.height ?? 0;

        if (width <= 0 || height <= 0) {
          html.Url.revokeObjectUrl(url);
          completer.complete(inputBytes);
          return;
        }

        // Calculate aspect ratio preserving dimensions
        if (width > maxWidth || height > maxHeight) {
          if (width >= height) {
            height = (height * maxWidth / width).round();
            width = maxWidth;
          } else {
            width = (width * maxHeight / height).round();
            height = maxHeight;
          }
        }

        // Create HTML Canvas for browser-native rendering pipeline
        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        ctx.drawImageScaled(image, 0, 0, width, height);

        // Export canvas as JPEG with requested quality parameter (e.g. 0.7 - 0.8)
        final dataUrl = canvas.toDataUrl('image/jpeg', quality);
        html.Url.revokeObjectUrl(url);

        // Decode base64 JPEG data to Uint8List
        final base64String = dataUrl.split(',').last;
        final compressedBytes = base64Decode(base64String);

        completer.complete(compressedBytes);
      } catch (_) {
        html.Url.revokeObjectUrl(url);
        completer.complete(inputBytes);
      }
    });

    image.onError.listen((_) {
      html.Url.revokeObjectUrl(url);
      completer.complete(inputBytes);
    });

    image.src = url;
    return completer.future;
  } catch (_) {
    return inputBytes;
  }
}
