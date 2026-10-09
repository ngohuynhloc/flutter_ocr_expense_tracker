import '../../transactions/models/expense_category.dart';

class ParsedReceiptResult {
  final String merchantName;
  final double amount;
  final DateTime transactionDate;
  final ExpenseCategory predictedCategory;
  final String rawText;
  final double confidenceScore;

  const ParsedReceiptResult({
    required this.merchantName,
    required this.amount,
    required this.transactionDate,
    required this.predictedCategory,
    required this.rawText,
    this.confidenceScore = 1.0,
  });

  @override
  String toString() {
    return 'ParsedReceiptResult(merchant: $merchantName, amount: $amount, date: $transactionDate, category: ${predictedCategory.name})';
  }
}
