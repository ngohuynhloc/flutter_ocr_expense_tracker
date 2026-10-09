import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'weekly_bar_chart_painter.dart';

class WeeklySpendingBarChart extends StatefulWidget {
  final List<double> weeklySpending; // 7 giá trị từ Thứ 2 đến Chủ nhật
  final DateTime? selectedWeekMonday;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final VoidCallback? onCurrentWeek;

  const WeeklySpendingBarChart({
    super.key,
    required this.weeklySpending,
    this.selectedWeekMonday,
    this.onPreviousWeek,
    this.onNextWeek,
    this.onCurrentWeek,
  });

  @override
  State<WeeklySpendingBarChart> createState() => _WeeklySpendingBarChartState();
}

class _WeeklySpendingBarChartState extends State<WeeklySpendingBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklySpendingBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklySpending != widget.weeklySpending ||
        oldWidget.selectedWeekMonday != widget.selectedWeekMonday) {
      _selectedDayIndex = null;
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
    const double leftPadding = 48.0;
    final double chartWidth = size.width - leftPadding;
    final double slotWidth = chartWidth / 7;

    final touchX = details.localPosition.dx;
    if (touchX < leftPadding || touchX > size.width) {
      setState(() => _selectedDayIndex = null);
      return;
    }

    final tappedIndex = ((touchX - leftPadding) / slotWidth).floor();
    if (tappedIndex >= 0 && tappedIndex < 7) {
      setState(() {
        _selectedDayIndex = (_selectedDayIndex == tappedIndex) ? null : tappedIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm',
      'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];

    final double weekTotal = widget.weeklySpending.fold(0.0, (sum, val) => sum + val);
    final monday = widget.selectedWeekMonday;
    final isCurrent = monday != null ? DateFormatter.isCurrentWeek(monday) : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Week Navigation Bar (nếu có callback)
        if (monday != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Tuần trước',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onPreviousWeek,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormatter.formatWeekRange(monday),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Tuần này',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tổng tuần: ${CurrencyFormatter.formatVND(weekTotal)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: weekTotal > 0 ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrent && widget.onCurrentWeek != null)
                  IconButton(
                    icon: const Icon(Icons.today_rounded, size: 20),
                    tooltip: 'Về tuần hiện tại',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onCurrentWeek,
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Tuần sau',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onNextWeek,
                ),
              ],
            ),
          ),

        // 2. Selected Day Info Tooltip
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 38,
          alignment: Alignment.center,
          child: _selectedDayIndex != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${dayNames[_selectedDayIndex!]}: ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(
                          widget.weeklySpending[_selectedDayIndex!],
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  'Chạm vào cột bất kỳ để xem chi tiết từng ngày',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
        ),

        const SizedBox(height: 6),

        // 3. CustomPainter Canvas Bar Chart
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return GestureDetector(
                onTapUp: (details) => _handleTap(details, size),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: size,
                      painter: WeeklyBarChartPainter(
                        dailySpending: widget.weeklySpending,
                        animationProgress: _animation.value,
                        selectedDayIndex: _selectedDayIndex,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
