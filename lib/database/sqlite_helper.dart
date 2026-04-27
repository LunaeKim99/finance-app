import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../models/asset_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import 'db_interface.dart';

class SqliteHelper implements DbInterface {
  static SqliteHelper? _instance;
  static Database? _database;

  factory SqliteHelper() {
    _instance ??= SqliteHelper._internal();
    return _instance!;
  }

  SqliteHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final String dbPath = join(dir.path, 'finance_app.db');

    return openDatabase(dbPath, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT,
        purchase_date TEXT,
        note TEXT,
        is_active INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        remaining_amount REAL,
        person_name TEXT,
        due_date TEXT,
        start_date TEXT,
        is_paid INTEGER,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        spent REAL,
        category TEXT,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        note TEXT,
        is_active INTEGER
      )
    ''');
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode & 0xFFFFFF).toRadixString(16);
    return '${timestamp.substring(timestamp.length - 8)}$random';
  }

  @override
  Future<void> initialize() async {
    await database;
  }

  // ============ TRANSACTIONS ============
  @override
  Future<List<TransactionModel>> fetchAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps
        .map((map) => TransactionModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel t) async {
    final db = await database;
    final newId = _generateId();
    final transactionWithId = t.copyWith(id: newId);
    await db.insert(
      'transactions',
      _toMapSqlite(transactionWithId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transactionWithId;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<TransactionModel> updateTransaction(
    String id,
    TransactionModel t,
  ) async {
    final db = await database;
    final updatedTransaction = t.copyWith(id: id);
    await db.update(
      'transactions',
      _toMapSqlite(updatedTransaction),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updatedTransaction;
  }

  @override
  Future<List<TransactionModel>> fetchTransactionsByMonth(
    int month,
    int year,
  ) async {
    final db = await database;
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = DateTime(year, month + 1, 0).day;
    final endStr =
        '$year-${month.toString().padLeft(2, '0')}-${endDay.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps
        .map((map) => TransactionModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  // ============ ASSETS ============
  @override
  Future<List<AssetModel>> fetchAllAssets() async {
    final db = await database;
    final maps = await db.query('assets', orderBy: 'purchase_date DESC');
    return maps
        .map((map) => AssetModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  @override
  Future<AssetModel> createAsset(AssetModel a) async {
    final db = await database;
    final newId = _generateId();
    final assetWithId = a.copyWith(id: newId);
    await db.insert(
      'assets',
      _toMapSqlite(assetWithId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return assetWithId;
  }

  @override
  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<AssetModel> updateAsset(String id, AssetModel a) async {
    final db = await database;
    final updatedAsset = a.copyWith(id: id);
    await db.update(
      'assets',
      _toMapSqlite(updatedAsset),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updatedAsset;
  }

  // ============ DEBTS ============
  @override
  Future<List<DebtModel>> fetchAllDebts() async {
    final db = await database;
    final maps = await db.query('debts', orderBy: 'start_date DESC');
    return maps
        .map((map) => DebtModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  @override
  Future<DebtModel> createDebt(DebtModel d) async {
    final db = await database;
    final newId = _generateId();
    final debtWithId = d.copyWith(id: newId);
    await db.insert(
      'debts',
      _toMapSqlite(debtWithId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return debtWithId;
  }

  @override
  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<DebtModel> updateDebt(String id, DebtModel d) async {
    final db = await database;
    final updatedDebt = d.copyWith(id: id);
    await db.update(
      'debts',
      _toMapSqlite(updatedDebt),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updatedDebt;
  }

  @override
  Future<List<DebtModel>> fetchUnpaidDebts() async {
    final db = await database;
    final maps = await db.query(
      'debts',
      where: 'is_paid = ?',
      whereArgs: [0],
      orderBy: 'due_date ASC',
    );
    return maps
        .map((map) => DebtModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  // ============ BUDGETS ============
  @override
  Future<List<BudgetModel>> fetchAllBudgets() async {
    final db = await database;
    final maps = await db.query('budgets', orderBy: 'year DESC, month DESC');
    return maps
        .map((map) => BudgetModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel b) async {
    final db = await database;
    final newId = _generateId();
    final budgetWithId = b.copyWith(id: newId);
    await db.insert(
      'budgets',
      _toMapSqlite(budgetWithId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return budgetWithId;
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<BudgetModel> updateBudget(String id, BudgetModel b) async {
    final db = await database;
    final updatedBudget = b.copyWith(id: id);
    await db.update(
      'budgets',
      _toMapSqlite(updatedBudget),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updatedBudget;
  }

  @override
  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      orderBy: 'created DESC',
    );
    return maps
        .map((map) => BudgetModel.fromMap(_normalizeDateMap(map)))
        .toList();
  }

  @override
  Future<void> updateBudgetSpent(String id, double spent) async {
    final db = await database;
    await db.update(
      'budgets',
      {'spent': spent},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ HELPERS ============
  Map<String, dynamic> _normalizeDateMap(Map<String, dynamic> map) {
    final normalized = Map<String, dynamic>.from(map);
    if (normalized['purchase_date'] != null &&
        normalized['purchase_date'] is String) {
      normalized['purchase_date'] = _parseSqliteDate(
        normalized['purchase_date'] as String,
      );
    }
    if (normalized['due_date'] != null && normalized['due_date'] is String) {
      normalized['due_date'] = _parseSqliteDate(
        normalized['due_date'] as String,
      );
    }
    if (normalized['start_date'] != null &&
        normalized['start_date'] is String) {
      normalized['start_date'] = _parseSqliteDate(
        normalized['start_date'] as String,
      );
    }
    if (normalized['date'] != null && normalized['date'] is String) {
      normalized['date'] = _parseSqliteDate(normalized['date'] as String);
    }
    if (normalized['is_active'] != null) {
      normalized['is_active'] = (normalized['is_active'] as int) == 1;
    }
    if (normalized['is_paid'] != null) {
      normalized['is_paid'] = (normalized['is_paid'] as int) == 1;
    }
    return normalized;
  }

  String _parseSqliteDate(String date) {
    if (date.contains('T')) {
      return date;
    }
    return '${date}T00:00:00.000';
  }

  Map<String, dynamic> _toMapSqlite(dynamic model) {
    if (model is TransactionModel) {
      return {
        'id': model.id,
        'title': model.title,
        'amount': model.amount,
        'type': model.type.value,
        'category': model.category,
        'date': model.date.toIso8601String().split('T')[0],
        'note': model.note,
      };
    }
    if (model is AssetModel) {
      return {
        'id': model.id,
        'name': model.name,
        'type': model.type,
        'amount': model.amount,
        'currency': model.currency,
        'purchase_date': model.purchaseDate?.toIso8601String().split('T')[0],
        'note': model.note,
        'is_active': model.isActive ? 1 : 0,
      };
    }
    if (model is DebtModel) {
      return {
        'id': model.id,
        'title': model.title,
        'type': model.type,
        'amount': model.amount,
        'remaining_amount': model.remainingAmount ?? model.amount,
        'person_name': model.personName,
        'due_date': model.dueDate?.toIso8601String().split('T')[0],
        'start_date': model.startDate?.toIso8601String().split('T')[0],
        'is_paid': model.isPaid ? 1 : 0,
        'note': model.note,
      };
    }
    if (model is BudgetModel) {
      return {
        'id': model.id,
        'name': model.name,
        'amount': model.amount,
        'spent': model.spent,
        'category': model.category,
        'month': model.month,
        'year': model.year,
        'note': model.note,
        'is_active': model.isActive ? 1 : 0,
      };
    }
    throw Exception('Unknown model type');
  }
}
