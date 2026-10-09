import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/expense_category.dart';
import '../models/transaction_model.dart';

abstract class ITransactionRepository {
  Future<int> insertTransaction(TransactionModel transaction);
  Future<int> updateTransaction(TransactionModel transaction);
  Future<int> deleteTransaction(int id);
  Future<TransactionModel?> getTransactionById(int id);
  Future<List<TransactionModel>> getAllTransactions({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<double> getTotalSpending({DateTime? startDate, DateTime? endDate});
  Future<Map<ExpenseCategory, double>> getSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<double>> getWeeklyDailySpending(DateTime startOfWeekMonday);
}

class TransactionRepository implements ITransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return 0;
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<TransactionModel>> getAllTransactions({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (category != null) {
      whereClauses.add('${DatabaseHelper.colCategory} = ?');
      whereArgs.add(category.toDbString());
    }

    if (startDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final String? whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${DatabaseHelper.colTransactionDate} DESC',
    );

    return maps.map((e) => TransactionModel.fromMap(e)).toList();
  }

  @override
  Future<double> getTotalSpending({DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final String whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseHelper.colAmount}) as total FROM ${DatabaseHelper.tableTransactions} $whereSql',
      whereArgs,
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  @override
  Future<Map<ExpenseCategory, double>> getSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('${DatabaseHelper.colTransactionDate} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final String whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT ${DatabaseHelper.colCategory}, SUM(${DatabaseHelper.colAmount}) as category_total
      FROM ${DatabaseHelper.tableTransactions}
      $whereSql
      GROUP BY ${DatabaseHelper.colCategory}
    ''', whereArgs);

    final Map<ExpenseCategory, double> categoryMap = {};
    for (final row in result) {
      final category = ExpenseCategory.fromDbString(row['category'] as String?);
      final total = (row['category_total'] as num?)?.toDouble() ?? 0.0;
      categoryMap[category] = total;
    }

    return categoryMap;
  }

  @override
  Future<List<double>> getWeeklyDailySpending(DateTime startOfWeekMonday) async {
    final monday = DateTime(
      startOfWeekMonday.year,
      startOfWeekMonday.month,
      startOfWeekMonday.day,
    );
    final sundayEnd = DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
      23, 59, 59, 999,
    );

    final transactions = await getAllTransactions(
      startDate: monday,
      endDate: sundayEnd,
    );

    // List 7 ngày từ Thứ 2 đến Chủ nhật
    final List<double> dailyTotals = List.filled(7, 0.0);

    for (final tx in transactions) {
      final txDay = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      final diffDays = txDay.difference(monday).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        dailyTotals[diffDays] += tx.amount;
      }
    }

    return dailyTotals;
  }
}
