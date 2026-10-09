import 'expense_category.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime transactionDate;
  final String? imagePath;
  final String? rawOcrText;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.transactionDate,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? transactionDate;

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? transactionDate,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.toDbString(),
      'transaction_date': transactionDate.toIso8601String(),
      'image_path': imagePath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Chi tiêu chưa đặt tên',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromDbString(map['category'] as String?),
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePath: map['image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, category: ${category.name}, date: $transactionDate)';
  }
}
