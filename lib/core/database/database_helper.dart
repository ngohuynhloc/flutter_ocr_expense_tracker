import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'expense_tracker.db';
  static const int _dbVersion = 1;

  static const String tableTransactions = 'transactions';

  // Columns
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colTransactionDate = 'transaction_date';
  static const String colImagePath = 'image_path';
  static const String colRawOcrText = 'raw_ocr_text';
  static const String colCreatedAt = 'created_at';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colCategory TEXT NOT NULL,
        $colTransactionDate TEXT NOT NULL,
        $colImagePath TEXT,
        $colRawOcrText TEXT,
        $colCreatedAt TEXT NOT NULL
      )
    ''');

    // Tạo Index để tối ưu truy vấn theo ngày & danh mục cho biểu đồ
    await db.execute(
      'CREATE INDEX idx_transactions_date ON $tableTransactions ($colTransactionDate)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON $tableTransactions ($colCategory)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
