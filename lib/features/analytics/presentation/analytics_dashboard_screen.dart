import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../transactions/models/expense_category.dart';
import '../../transactions/models/time_period_filter.dart';
import '../widgets/animated_donut_chart.dart';
import '../widgets/weekly_spending_bar_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final TransactionController controller;

  const AnalyticsDashboardScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final total = controller.totalSpending;
    final spendingByCategory = controller.spendingByCategory;
    final weeklySpending = controller.weeklySpending;
    final selectedPeriod = controller.selectedPeriodFilter;

    // Tìm danh mục chi tiêu nhiều nhất
    ExpenseCategory? topCategory;
    double maxCategorySpending = 0.0;
    for (final entry in spendingByCategory.entries) {
      if (entry.value > maxCategorySpending) {
        maxCategorySpending = entry.value;
        topCategory = entry.key;
      }
    }

    final topCategoryPercentage = total > 0
        ? ((maxCategorySpending / total) * 100).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiêu'),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadAllData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bộ lọc khoảng thời gian (All-time, Tuần này, Tháng này, Tháng trước)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: TimePeriodFilter.values.map((filter) {
                    final isSelected = selectedPeriod == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => controller.setPeriodFilter(filter),
                        selectedColor: AppColors.primaryLight.withOpacity(0.4),
                        checkmarkColor: AppColors.primary,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Thẻ tóm tắt chỉ số nhanh
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Tổng (${selectedPeriod.displayName})',
                      value: CurrencyFormatter.formatVND(total),
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Khoản chi lớn nhất',
                      value: topCategory != null
                          ? '${topCategory.displayName} ($topCategoryPercentage%)'
                          : 'Chưa có dữ liệu',
                      icon: topCategory?.icon ?? Icons.category_rounded,
                      color: topCategory?.color ?? AppColors.categoryOthers,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Biểu đồ cột Weekly Spending (hỗ trợ chuyển tuần)
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Chi tiêu theo ngày trong tuần',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      WeeklySpendingBarChart(
                        weeklySpending: weeklySpending,
                        selectedWeekMonday: controller.selectedWeekMonday,
                        onPreviousWeek: () => controller.goToPreviousWeek(),
                        onNextWeek: () => controller.goToNextWeek(),
                        onCurrentWeek: () => controller.goToCurrentWeek(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4. Biểu đồ tròn Donut Chart
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.donut_large_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Phân bổ danh mục (${selectedPeriod.displayName})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedDonutChart(
                        data: spendingByCategory,
                        totalAmount: total,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 5. Chi tiết từng danh mục
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiết danh mục (${selectedPeriod.displayName})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (spendingByCategory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không có giao dịch nào trong khoảng thời gian này',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...spendingByCategory.entries.map((entry) {
                          final cat = entry.key;
                          final amount = entry.value;
                          final ratio = total > 0 ? (amount / total) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(cat.icon, color: cat.color, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat.displayName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      CurrencyFormatter.formatVND(amount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
