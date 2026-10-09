import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/transaction_controller.dart';
import '../models/expense_category.dart';
import '../models/time_period_filter.dart';
import '../models/transaction_model.dart';
import 'widgets/add_edit_transaction_dialog.dart';
import 'widgets/transaction_card.dart';

class TransactionListScreen extends StatefulWidget {
  final TransactionController controller;
  final VoidCallback? onScanReceiptTap;
  final VoidCallback? onAnalyticsTap;

  const TransactionListScreen({
    super.key,
    required this.controller,
    this.onScanReceiptTap,
    this.onAnalyticsTap,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    widget.controller.loadAllData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _showAddEditDialog([TransactionModel? existing]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditTransactionDialog(
        initialTransaction: existing,
        onSave: (tx) {
          if (existing == null) {
            widget.controller.addTransaction(tx);
          } else {
            widget.controller.updateTransaction(tx);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Expense Tracker'),
        actions: [
          if (widget.onAnalyticsTap != null)
            IconButton(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              tooltip: 'Thống kê',
              onPressed: widget.onAnalyticsTap,
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.loadAllData(),
              child: CustomScrollView(
                slivers: [
                  // Total Spending Header Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng chi tiêu (${controller.selectedPeriodFilter.displayName})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.formatVND(controller.totalSpending),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${controller.transactions.length} giao dịch',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 1. Time Period Filter Horizontal List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: TimePeriodFilter.values.map((filter) {
                          final isSelected = controller.selectedPeriodFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                filter.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => controller.setPeriodFilter(filter),
                              selectedColor: AppColors.primaryLight.withOpacity(0.4),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 6)),

                  // 2. Category Filter Horizontal List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('Tất cả danh mục'),
                              selected: controller.selectedCategoryFilter == null,
                              onSelected: (_) => controller.filterByCategory(null),
                              selectedColor: AppColors.primary.withOpacity(0.18),
                            ),
                          ),
                          ...ExpenseCategory.values.map((cat) {
                            final isSelected = controller.selectedCategoryFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: Icon(cat.icon, size: 16, color: cat.color),
                                label: Text(cat.displayName),
                                selected: isSelected,
                                onSelected: (_) => controller.filterByCategory(cat),
                                selectedColor: cat.color.withOpacity(0.18),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Transactions List or Empty State
                  if (controller.transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.selectedCategoryFilter != null
                                  ? 'Không có chi tiêu nào trong danh mục này'
                                  : 'Chưa có chi tiêu nào được lưu',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn nút bên dưới để thêm hoặc quét hoá đơn',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = controller.transactions[index];
                          return TransactionCard(
                            transaction: tx,
                            onTap: () => _showAddEditDialog(tx),
                            onDelete: () {
                              if (tx.id != null) {
                                controller.deleteTransaction(tx.id!);
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Đã xoá "${tx.title}"'),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    action: SnackBarAction(
                                      label: 'Hoàn tác',
                                      textColor: Colors.amberAccent,
                                      onPressed: () {
                                        messenger.hideCurrentSnackBar();
                                        controller.addTransaction(tx);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                        childCount: controller.transactions.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Manual Add Button
            FloatingActionButton.extended(
              heroTag: 'manual_add_btn',
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm tay'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 3,
            ),
            const SizedBox(width: 14),
            // Scan Receipt Button
            FloatingActionButton.extended(
              heroTag: 'scan_ocr_btn',
              onPressed: widget.onScanReceiptTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng quét hoá đơn sẵn sàng trong Giai đoạn 2 & 3!'),
                  ),
                );
              },
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Quét hoá đơn'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ],
        ),
      ),
    );
  }
}
