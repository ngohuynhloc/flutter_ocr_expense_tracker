import 'package:flutter/material.dart';

class CameraOverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  final double cornerLength;
  final double cornerStrokeWidth;
  final Color cornerColor;
  final Color overlayColor;

  CameraOverlayPainter({
    required this.cutoutRect,
    this.cornerLength = 32.0,
    this.cornerStrokeWidth = 4.0,
    this.cornerColor = Colors.white,
    this.overlayColor = const Color(0x99000000), // 60% black
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)));

    // Đục lỗ vùng khung ngắm hoá đơn
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // Vẽ viền mờ quanh khung
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)), borderPaint);

    // Vẽ 4 góc định vị (Corner Brackets) nổi bật
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth
      ..strokeCap = StrokeCap.round;

    final left = cutoutRect.left;
    final top = cutoutRect.top;
    final right = cutoutRect.right;
    final bottom = cutoutRect.bottom;
    const radius = 16.0;

    // Góc trên bên trái
    canvas.drawLine(Offset(left + radius, top), Offset(left + radius + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top + radius), Offset(left, top + radius + cornerLength), cornerPaint);

    // Góc trên bên phải
    canvas.drawLine(Offset(right - radius, top), Offset(right - radius - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(right, top + radius), Offset(right, top + radius + cornerLength), cornerPaint);

    // Góc dưới bên trái
    canvas.drawLine(Offset(left + radius, bottom), Offset(left + radius + cornerLength, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom - radius), Offset(left, bottom - radius - cornerLength), cornerPaint);

    // Góc dưới bên phải
    canvas.drawLine(Offset(right - radius, bottom), Offset(right - radius - cornerLength, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom - radius), Offset(right, bottom - radius - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.cornerColor != cornerColor;
  }
}
