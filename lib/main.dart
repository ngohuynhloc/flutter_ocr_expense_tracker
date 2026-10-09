import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/presentation/analytics_dashboard_screen.dart';
import 'features/receipt_scan/presentation/camera_scanner_screen.dart';
import 'features/transactions/controllers/transaction_controller.dart';
import 'features/transactions/presentation/transaction_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OcrExpenseTrackerApp());
}

class OcrExpenseTrackerApp extends StatefulWidget {
  const OcrExpenseTrackerApp({super.key});

  @override
  State<OcrExpenseTrackerApp> createState() => _OcrExpenseTrackerAppState();
}

class _OcrExpenseTrackerAppState extends State<OcrExpenseTrackerApp> {
  late final TransactionController _transactionController;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => TransactionListScreen(
          controller: _transactionController,
          onAnalyticsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalyticsDashboardScreen(
                  controller: _transactionController,
                ),
              ),
            );
          },
          onScanReceiptTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CameraScannerScreen(
                  onTransactionSaved: (tx) {
                    _transactionController.addTransaction(tx);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã lưu chi tiêu: "${tx.title}"'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
