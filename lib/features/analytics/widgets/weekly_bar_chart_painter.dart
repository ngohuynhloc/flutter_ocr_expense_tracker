import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

class WeeklyBarChartPainter extends CustomPainter {
  final List<double> dailySpending; // 7 ngày: T2 -> CN
  final double animationProgress;
  final int? selectedDayIndex; // 0: Thứ 2, ... 6: Chủ nhật

  static const List<String> dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  WeeklyBarChartPainter({
    required this.dailySpending,
    required this.animationProgress,
    this.selectedDayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 48.0;
    const double bottomPadding = 28.0;
    const double topPadding = 16.0;

    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding - topPadding;

    // Tìm giá trị chi tiêu lớn nhất để chuẩn hoá tỉ lệ cột
    final double maxVal = dailySpending.fold(0.0, math.max);
    final double effectiveMax = maxVal > 0 ? maxVal * 1.15 : 100000.0;

    // 1. Vẽ các đường lưới ngang và nhãn trục Y
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    const int gridDivisions = 3;
    for (int i = 0; i <= gridDivisions; i++) {
      final ratio = i / gridDivisions;
      final y = (size.height - bottomPadding) - (ratio * chartHeight);

      // Vẽ nét ngang
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Nhãn trục Y
      final yVal = ratio * effectiveMax;
      final textSpan = TextSpan(
        text: CurrencyFormatter.formatCompact(yVal),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    // 2. Vẽ 7 cột chi tiêu
    final double slotWidth = chartWidth / 7;
    final double barWidth = slotWidth * 0.52;

    for (int i = 0; i < 7; i++) {
      final double val = i < dailySpending.length ? dailySpending[i] : 0.0;
      final double barHeightRatio = (val / effectiveMax).clamp(0.0, 1.0);
      final double barHeight = barHeightRatio * chartHeight * animationProgress;

      final double barLeft = leftPadding + (i * slotWidth) + ((slotWidth - barWidth) / 2);
      final double barRight = barLeft + barWidth;
      final double barBottom = size.height - bottomPadding;
      final double barTop = barBottom - barHeight;

      final isSelected = i == selectedDayIndex;

      // Màu sắc cột
      final barPaint = Paint()
        ..color = isSelected
            ? AppColors.primaryDark
            : (val > 0 ? AppColors.primary : Colors.grey.shade200)
        ..style = PaintingStyle.fill;

      // Vẽ cột có bo tròn 2 góc trên
      final rect = Rect.fromLTRB(barLeft, barTop, barRight, barBottom);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, barPaint);

      // Nếu cột được chọn, vẽ điểm nhấn sáng trên đầu cột
      if (isSelected && barHeight > 6) {
        final highlightPaint = Paint()
          ..color = Colors.amberAccent
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(barLeft + 2, barTop),
          Offset(barRight - 2, barTop),
          highlightPaint,
        );
      }

      // 3. Nhãn ngày ở trục X
      final labelSpan = TextSpan(
        text: dayLabels[i],
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          barLeft + (barWidth / 2) - (labelPainter.width / 2),
          barBottom + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedDayIndex != selectedDayIndex ||
        oldDelegate.dailySpending != dailySpending;
  }
}
