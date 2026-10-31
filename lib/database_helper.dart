import 'package:flutter/material.dart';
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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_income INTEGER NOT NULL DEFAULT 0
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

    final categories = <Map<String, Object?>>[
      {'name': 'Ăn uống', 'icon_code': Icons.restaurant.codePoint, 'color_value': 0xFFF44336, 'is_income': 0},
      {'name': 'Di chuyển', 'icon_code': Icons.directions_car.codePoint, 'color_value': 0xFF2196F3, 'is_income': 0},
      {'name': 'Mua sắm', 'icon_code': Icons.shopping_bag.codePoint, 'color_value': 0xFFFF9800, 'is_income': 0},
      {'name': 'Giải trí', 'icon_code': Icons.movie.codePoint, 'color_value': 0xFF9C27B0, 'is_income': 0},
      {'name': 'Hóa đơn', 'icon_code': Icons.receipt_long.codePoint, 'color_value': 0xFF607D8B, 'is_income': 0},
      {'name': 'Lương', 'icon_code': Icons.payments.codePoint, 'color_value': 0xFF4CAF50, 'is_income': 1},
      {'name': 'Thưởng', 'icon_code': Icons.card_giftcard.codePoint, 'color_value': 0xFF00BCD4, 'is_income': 1},
    ];
    for (final c in categories) {
      await db.insert('categories', c);
    }
  }

  // Danh mục theo loại: chi tiêu (isIncome = false) hoặc thu nhập (isIncome = true)
  Future<List<Map<String, Object?>>> getCategories({required bool isIncome}) async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'is_income = ?',
      whereArgs: [isIncome ? 1 : 0],
    );
  }

  Future<int> insertTransaction(Map<String, Object?> row) async {
    final db = await database;
    return await db.insert('transactions', row);
  }

  Future<int> updateTransaction(int id, Map<String, Object?> row) async {
    final db = await database;
    return await db.update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.id, t.category_id, t.amount, t.is_expense, t.transaction_date, t.note,
             c.name AS category_name, c.icon_code, c.color_value
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      ORDER BY t.transaction_date DESC, t.id DESC
    ''');
  }

  // Trả về tổng thu và tổng chi
  Future<Map<String, double>> getTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN is_expense = 0 THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN is_expense = 1 THEN amount END), 0) AS expense
      FROM transactions
    ''');
    final row = result.first;
    return {
      'income': (row['income'] as num).toDouble(),
      'expense': (row['expense'] as num).toDouble(),
    };
  }
}