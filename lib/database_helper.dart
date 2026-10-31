import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Dữ liệu mẫu cho danh mục
    final categories = [
      {'name': 'Ăn uống', 'icon_code': 0xe56c, 'color_value': 0xFFF44336},
      {'name': 'Di chuyển', 'icon_code': 0xe1d7, 'color_value': 0xFF2196F3},
      {'name': 'Mua sắm', 'icon_code': 0xe59c, 'color_value': 0xFFFF9800},
      {'name': 'Giải trí', 'icon_code': 0xe40a, 'color_value': 0xFF9C27B0},
      {'name': 'Hóa đơn', 'icon_code': 0xe8b0, 'color_value': 0xFF607D8B},
    ];
    for (final c in categories) {
      await db.insert('categories', c);
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT t.id, t.amount, t.is_expense, t.transaction_date, t.note,
             c.name AS category_name, c.icon_code, c.color_value
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      ORDER BY t.transaction_date DESC, t.id DESC
    ''');
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getBalanceTotals() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN is_expense = 0 THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN is_expense = 1 THEN amount ELSE 0 END), 0) AS balance
      FROM transactions
    ''');
    return (result.first['balance'] as num).toDouble();
  }
}