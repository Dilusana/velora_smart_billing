import 'package:flutter/material.dart';

/// Paints light grey abstract dot/circle "supermarket" texture plus soft
/// green decorative waves anchored to the bottom corners of the screen.
class KioskBackgroundPainter extends CustomPainter {
  const KioskBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintAbstractPattern(canvas, size);
    _paintBottomWaves(canvas, size);
  }

  void _paintAbstractPattern(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()
      ..color = const Color(0xFFEFF2EF)
      ..style = PaintingStyle.fill;

    // Sparse grid of soft circles evoking shelves / produce, kept very
    // subtle so it never competes with the foreground content.
    const double spacing = 90;
    for (double y = -spacing; y < size.height; y += spacing) {
      for (double x = -spacing; x < size.width; x += spacing) {
        final double radius = ((x + y) % 180 == 0) ? 22 : 14;
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFFF1F3F1)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (double x = -spacing; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        linePaint,
      );
    }
  }

  void _paintBottomWaves(Canvas canvas, Size size) {
    // Bottom-left wave.
    final Paint leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x332ECC71), Color(0x1116A34A)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, size.height - 220, 420, 220));

    final Path leftPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 160)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height - 240,
        size.width * 0.22,
        size.height - 140,
      )
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height - 70,
        size.width * 0.16,
        size.height,
      )
      ..close();
    canvas.drawPath(leftPath, leftPaint);

    // Bottom-right wave.
    final Paint rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x332ECC71), Color(0x1116A34A)],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ).createShader(
        Rect.fromLTWH(size.width - 420, size.height - 220, 420, 220),
      );

    final Path rightPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, size.height - 180)
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height - 260,
        size.width * 0.80,
        size.height - 150,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height - 60,
        size.width * 0.86,
        size.height,
      )
      ..close();
    canvas.drawPath(rightPath, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
