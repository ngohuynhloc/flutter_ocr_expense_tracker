import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../transactions/models/expense_category.dart';

class DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double animationProgress; // 0.0 -> 1.0
  final ExpenseCategory? selectedCategory;
  final double strokeWidth;

  DonutChartPainter({
    required this.data,
    required this.animationProgress,
    this.selectedCategory,
    this.strokeWidth = 32.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final double total = data.values.fold(0.0, (sum, val) => sum + val);

    // Nếu không có dữ liệu chi tiêu, vẽ vòng tròn rỗng màu xám mờ
    if (total <= 0) {
      final emptyPaint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, baseRadius, emptyPaint);
      return;
    }

    // Bắt đầu từ đỉnh 12 giờ (-pi / 2)
    double startAngle = -math.pi / 2;

    for (final entry in data.entries) {
      final category = entry.key;
      final amount = entry.value;
      if (amount <= 0) continue;

      final isSelected = category == selectedCategory;
      final sweepAngle = (amount / total) * 2 * math.pi * animationProgress;

      // Slice được chọn sẽ hơi nhô ra ngoài (radius lớn hơn) và đậm hơn
      final sliceRadius = isSelected ? baseRadius + 4 : baseRadius;
      final currentStroke = isSelected ? strokeWidth + 6 : strokeWidth;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt;

      final arcRect = Rect.fromCircle(center: center, radius: sliceRadius);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);

      // Nếu đang vẽ nhiều lát, thêm đường phân cách mỏng
      if (data.length > 1) {
        final separatorPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(arcRect, startAngle, 0.02, false, separatorPaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.data != data;
  }
}
