import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/models/expense_category.dart';
import 'donut_chart_painter.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;
    final dx = touchPosition.dx - center.dx;
    final dy = touchPosition.dy - center.dy;

    final distance = math.sqrt(dx * dx + dy * dy);
    const strokeWidth = 32.0;
    final baseRadius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final innerRadius = baseRadius - (strokeWidth / 2);
    final outerRadius = baseRadius + (strokeWidth / 2) + 8;

    // Kiểm tra xem vị trí chạm có nằm trong vòng tròn Donut không
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selectedCategory = null);
      return;
    }

    // Tính góc chạm so với đỉnh 12 giờ
    double touchAngle = math.atan2(dy, dx) + (math.pi / 2);
    if (touchAngle < 0) {
      touchAngle += 2 * math.pi;
    }

    // Tìm category tương ứng với góc chạm
    double cumulativeAngle = 0.0;
    final total = widget.totalAmount;
    if (total <= 0) return;

    for (final entry in widget.data.entries) {
      if (entry.value <= 0) continue;
      final sliceAngle = (entry.value / total) * 2 * math.pi;
      if (touchAngle >= cumulativeAngle && touchAngle <= cumulativeAngle + sliceAngle) {
        setState(() {
          _selectedCategory = (_selectedCategory == entry.key) ? null : entry.key;
        });
        return;
      }
      cumulativeAngle += sliceAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validData = Map<ExpenseCategory, double>.from(widget.data)
      ..removeWhere((_, val) => val <= 0);

    return Column(
      children: [
        // Donut Canvas with Center Info
        SizedBox(
          width: 220,
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return GestureDetector(
                onTapUp: (details) => _handleTap(details, size),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: size,
                          painter: DonutChartPainter(
                            data: validData,
                            animationProgress: _animation.value,
                            selectedCategory: _selectedCategory,
                          ),
                        );
                      },
                    ),
                    // Center Info Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? _selectedCategory!.displayName
                                : 'Tổng cộng',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatVND(
                              _selectedCategory != null
                                  ? (widget.data[_selectedCategory] ?? 0.0)
                                  : widget.totalAmount,
                            ),
                            style: TextStyle(
                              fontSize: _selectedCategory != null ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: _selectedCategory != null
                                  ? _selectedCategory!.color
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedCategory != null && widget.totalAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${(((widget.data[_selectedCategory] ?? 0.0) / widget.totalAmount) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategory!.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Legend Items
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: validData.entries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final isSelected = _selectedCategory == category;
            final pct = widget.totalAmount > 0
                ? ((amount / widget.totalAmount) * 100).toStringAsFixed(1)
                : '0';

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.displayName} ($pct%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? category.color : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
