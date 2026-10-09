import 'package:flutter/foundation.dart';
import '../models/expense_category.dart';
import '../models/time_period_filter.dart';
import '../models/transaction_model.dart';
import '../repository/transaction_repository.dart';

class TransactionController extends ChangeNotifier {
  final ITransactionRepository _repository;

  TransactionController({ITransactionRepository? repository})
      : _repository = repository ?? TransactionRepository() {
    final now = DateTime.now();
    _selectedWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  List<TransactionModel> _transactions = [];
  Map<ExpenseCategory, double> _spendingByCategory = {};
  List<double> _weeklySpending = List.filled(7, 0.0);
  double _totalSpending = 0.0;
  bool _isLoading = false;
  ExpenseCategory? _selectedCategoryFilter;

  // Time navigation state
  late DateTime _selectedWeekMonday;
  TimePeriodFilter _selectedPeriodFilter = TimePeriodFilter.allTime;

  List<TransactionModel> get transactions => _transactions;
  Map<ExpenseCategory, double> get spendingByCategory => _spendingByCategory;
  List<double> get weeklySpending => _weeklySpending;
  double get totalSpending => _totalSpending;
  bool get isLoading => _isLoading;
  ExpenseCategory? get selectedCategoryFilter => _selectedCategoryFilter;
  DateTime get selectedWeekMonday => _selectedWeekMonday;
  TimePeriodFilter get selectedPeriodFilter => _selectedPeriodFilter;

  double get selectedWeekTotal =>
      _weeklySpending.fold(0.0, (sum, val) => sum + val);

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateRange = _selectedPeriodFilter.getDateRange();

      _transactions = await _repository.getAllTransactions(
        category: _selectedCategoryFilter,
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      _totalSpending = await _repository.getTotalSpending(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      _spendingByCategory = await _repository.getSpendingByCategory(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      // Tải dữ liệu biểu đồ cột theo tuần được chọn
      _weeklySpending = await _repository.getWeeklyDailySpending(_selectedWeekMonday);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriodFilter(TimePeriodFilter filter) {
    if (_selectedPeriodFilter != filter) {
      _selectedPeriodFilter = filter;
      loadAllData();
    }
  }

  void filterByCategory(ExpenseCategory? category) {
    if (_selectedCategoryFilter == category) {
      _selectedCategoryFilter = null; // Toggle bỏ lọc
    } else {
      _selectedCategoryFilter = category;
    }
    loadAllData();
  }

  // Week Navigation for Bar Chart
  Future<void> goToPreviousWeek() async {
    _selectedWeekMonday = _selectedWeekMonday.subtract(const Duration(days: 7));
    _weeklySpending = await _repository.getWeeklyDailySpending(_selectedWeekMonday);
    notifyListeners();
  }

  Future<void> goToNextWeek() async {
    _selectedWeekMonday = _selectedWeekMonday.add(const Duration(days: 7));
    _weeklySpending = await _repository.getWeeklyDailySpending(_selectedWeekMonday);
    notifyListeners();
  }

  Future<void> goToCurrentWeek() async {
    final now = DateTime.now();
    _selectedWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _weeklySpending = await _repository.getWeeklyDailySpending(_selectedWeekMonday);
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.insertTransaction(transaction);
    await loadAllData();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    await loadAllData();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    await loadAllData();
  }
}
