import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/pb_client.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import 'local/sqlite_helper.dart';
import 'pb_helper.dart';
import 'sync_queue_helper.dart';
import 'db_interface.dart';

class SmartDbHelper implements DbInterface {
  static SmartDbHelper? _instance;

  final PbHelper remote;
  final SqliteHelper local;
  final SyncQueueHelper _syncQueue = SyncQueueHelper();

  bool _isRemoteAvailable = false;
  bool _initialized = false;
  Timer? _connectivityTimer;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isRemoteAvailable => _isRemoteAvailable;

  factory SmartDbHelper({required PbHelper remote, required SqliteHelper local}) {
    _instance ??= SmartDbHelper._internal(remote: remote, local: local);
    return _instance!;
  }

  SmartDbHelper._internal({required this.remote, required this.local});

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await Future.wait([
      remote.initialize(),
      local.initialize(),
    ]);

    _isRemoteAvailable = await PbClient.isConnected();
    _connectivityController.add(_isRemoteAvailable);

    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );

    _initialized = true;
  }

  Future<void> refreshConnectivity() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final wasAvailable = _isRemoteAvailable;
    _isRemoteAvailable = await PbClient.isConnected();

    if (_isRemoteAvailable && !wasAvailable) {
      await syncPendingToRemote();
    }

    if (_isRemoteAvailable != wasAvailable) {
      _connectivityController.add(_isRemoteAvailable);
    }
  }

  Future<T> _exec<T>({
    required Future<T> Function() remoteOp,
    required Future<T> Function() localOp,
    bool isWrite = false,
    Future<void> Function()? queueOp,
    Future<void> Function(T)? writeThrough,
  }) async {
    if (_isRemoteAvailable) {
      try {
        final result = await remoteOp();
        if (writeThrough != null) await writeThrough(result);
        return result;
      } catch (e) {
        debugPrint('[SmartDbHelper] Remote failed: $e');
        _isRemoteAvailable = false;
        _connectivityController.add(false);
        if (isWrite && queueOp != null) await queueOp();
        return localOp();
      }
    }
    if (isWrite && queueOp != null) await queueOp();
    return localOp();
  }

  // ============ WRITE-THROUGH HELPERS ============

  Future<void> _writeThroughTransaction(TransactionModel t) async {
    final db = await local.database;
    await db.insert('transactions', {
      'id': t.id,
      'title': t.title,
      'amount': t.amount,
      'type': t.type.value,
      'category': t.categoryId,
      'date': t.date.toIso8601String().split('T')[0],
      'note': t.note,
      'currency': t.currency != 'IDR' ? t.currency : null,
      'exchange_rate_to_idr': t.exchangeRateToIdr != 1.0 ? t.exchangeRateToIdr : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeThroughAsset(AssetModel a) async {
    final db = await local.database;
    await db.insert('assets', {
      'id': a.id,
      'name': a.name,
      'type': a.type,
      'amount': a.amount,
      'currency': a.currency,
      'purchase_date': a.purchaseDate?.toIso8601String().split('T')[0],
      'note': a.note,
      'is_active': a.isActive ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeThroughDebt(DebtModel d) async {
    final db = await local.database;
    await db.insert('debts', {
      'id': d.id,
      'title': d.title,
      'type': d.type,
      'amount': d.amount,
      'remaining_amount': d.remainingAmount ?? d.amount,
      'person_name': d.personName,
      'due_date': d.dueDate?.toIso8601String().split('T')[0],
      'start_date': d.startDate?.toIso8601String().split('T')[0],
      'is_paid': d.isPaid ? 1 : 0,
      'note': d.note,
      'currency': d.currency != 'IDR' ? d.currency : null,
      'exchange_rate_to_idr': d.exchangeRateToIdr != 1.0 ? d.exchangeRateToIdr : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeThroughBudget(BudgetModel b) async {
    final db = await local.database;
    await db.insert('budgets', {
      'id': b.id,
      'name': b.name,
      'amount': b.amount,
      'spent': b.spent,
      'category': b.category,
      'month': b.month,
      'year': b.year,
      'note': b.note,
      'is_active': b.isActive ? 1 : 0,
      'currency': b.currency != 'IDR' ? b.currency : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeThroughCategory(CategoryModel c) async {
    final db = await local.database;
    await db.insert('categories', {
      'id': c.id,
      'name': c.name,
      'type': c.type,
      'icon': c.icon,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ============ SYNC ============

  Future<void> syncPendingToRemote() async {
    try {
      final pendingItems = await _syncQueue.getPendingItems();

      for (final item in pendingItems) {
        try {
          final id = item['id'] as int;
          final operation = item['operation'] as String;
          final collection = item['collection'] as String;
          final payloadStr = item['payload'] as String;
          final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

          switch ('$operation:$collection') {
            case 'create:transactions':
              await remote.createTransaction(
                TransactionModel.fromMap(payload),
              );
              break;
            case 'update:transactions':
              await remote.updateTransaction(
                payload['id'] as String,
                TransactionModel.fromMap(payload),
              );
              break;
            case 'delete:transactions':
              await remote.deleteTransaction(payload['id'] as String);
              break;
            case 'create:assets':
              await remote.createAsset(AssetModel.fromMap(payload));
              break;
            case 'update:assets':
              await remote.updateAsset(
                payload['id'] as String,
                AssetModel.fromMap(payload),
              );
              break;
            case 'delete:assets':
              await remote.deleteAsset(payload['id'] as String);
              break;
            case 'create:debts':
              await remote.createDebt(DebtModel.fromMap(payload));
              break;
            case 'update:debts':
              await remote.updateDebt(
                payload['id'] as String,
                DebtModel.fromMap(payload),
              );
              break;
            case 'delete:debts':
              await remote.deleteDebt(payload['id'] as String);
              break;
            case 'create:budgets':
              await remote.createBudget(BudgetModel.fromMap(payload));
              break;
            case 'update:budgets':
              await remote.updateBudget(
                payload['id'] as String,
                BudgetModel.fromMap(payload),
              );
              break;
            case 'delete:budgets':
              await remote.deleteBudget(payload['id'] as String);
              break;
            case 'update:budgets_spent':
              await remote.updateBudgetSpent(
                payload['id'] as String,
                (payload['spent'] as num).toDouble(),
              );
              break;
            case 'create:categories':
              await remote.createCategory(CategoryModel.fromMap(payload));
              break;
            case 'update:categories':
              await remote.updateCategory(
                payload['id'] as String,
                CategoryModel.fromMap(payload),
              );
              break;
            case 'delete:categories':
              await remote.deleteCategory(payload['id'] as String);
              break;
          }

          await _syncQueue.markSynced(id);
        } catch (e) {
          debugPrint('[SmartDbHelper] Sync error for item: $e');
          await _syncQueue.incrementRetryCount(item['id'] as int);
        }
      }

      await _syncQueue.deleteSyncedItems();
    } catch (e) {
      debugPrint('[SmartDbHelper] Error during sync: $e');
    }
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }

  // ============ TRANSACTIONS ============

  @override
  Future<List<TransactionModel>> fetchAllTransactions() async {
    return _exec(
      remoteOp: () => remote.fetchAllTransactions(),
      localOp: () => local.fetchAllTransactions(),
    );
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel t) async {
    return _exec(
      remoteOp: () => remote.createTransaction(t),
      localOp: () => local.createTransaction(t),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('create', 'transactions', t.toMap()),
      writeThrough: (result) => _writeThroughTransaction(result),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _exec<void>(
      remoteOp: () => remote.deleteTransaction(id),
      localOp: () => local.deleteTransaction(id),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('delete', 'transactions', {'id': id}),
    );
  }

  @override
  Future<TransactionModel> updateTransaction(
    String id,
    TransactionModel t,
  ) async {
    return _exec(
      remoteOp: () => remote.updateTransaction(id, t),
      localOp: () => local.updateTransaction(id, t),
      isWrite: true,
      queueOp: () =>
          _syncQueue.enqueue('update', 'transactions', t.toMap()),
      writeThrough: (result) => _writeThroughTransaction(result),
    );
  }

  @override
  Future<List<TransactionModel>> fetchTransactionsByMonth(
    int month,
    int year,
  ) async {
    return _exec(
      remoteOp: () => remote.fetchTransactionsByMonth(month, year),
      localOp: () => local.fetchTransactionsByMonth(month, year),
    );
  }

  // ============ ASSETS ============

  @override
  Future<List<AssetModel>> fetchAllAssets() async {
    return _exec(
      remoteOp: () => remote.fetchAllAssets(),
      localOp: () => local.fetchAllAssets(),
    );
  }

  @override
  Future<AssetModel> createAsset(AssetModel a) async {
    return _exec(
      remoteOp: () => remote.createAsset(a),
      localOp: () => local.createAsset(a),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('create', 'assets', a.toJson()),
      writeThrough: (result) => _writeThroughAsset(result),
    );
  }

  @override
  Future<void> deleteAsset(String id) async {
    await _exec<void>(
      remoteOp: () => remote.deleteAsset(id),
      localOp: () => local.deleteAsset(id),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('delete', 'assets', {'id': id}),
    );
  }

  @override
  Future<AssetModel> updateAsset(String id, AssetModel a) async {
    return _exec(
      remoteOp: () => remote.updateAsset(id, a),
      localOp: () => local.updateAsset(id, a),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('update', 'assets', a.toJson()),
      writeThrough: (result) => _writeThroughAsset(result),
    );
  }

  // ============ DEBTS ============

  @override
  Future<List<DebtModel>> fetchAllDebts() async {
    return _exec(
      remoteOp: () => remote.fetchAllDebts(),
      localOp: () => local.fetchAllDebts(),
    );
  }

  @override
  Future<DebtModel> createDebt(DebtModel d) async {
    return _exec(
      remoteOp: () => remote.createDebt(d),
      localOp: () => local.createDebt(d),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('create', 'debts', d.toJson()),
      writeThrough: (result) => _writeThroughDebt(result),
    );
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _exec<void>(
      remoteOp: () => remote.deleteDebt(id),
      localOp: () => local.deleteDebt(id),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('delete', 'debts', {'id': id}),
    );
  }

  @override
  Future<DebtModel> updateDebt(String id, DebtModel d) async {
    return _exec(
      remoteOp: () => remote.updateDebt(id, d),
      localOp: () => local.updateDebt(id, d),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('update', 'debts', d.toJson()),
      writeThrough: (result) => _writeThroughDebt(result),
    );
  }

  @override
  Future<List<DebtModel>> fetchUnpaidDebts() async {
    return _exec(
      remoteOp: () => remote.fetchUnpaidDebts(),
      localOp: () => local.fetchUnpaidDebts(),
    );
  }

  // ============ BUDGETS ============

  @override
  Future<List<BudgetModel>> fetchAllBudgets() async {
    return _exec(
      remoteOp: () => remote.fetchAllBudgets(),
      localOp: () => local.fetchAllBudgets(),
    );
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel b) async {
    return _exec(
      remoteOp: () => remote.createBudget(b),
      localOp: () => local.createBudget(b),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('create', 'budgets', b.toJson()),
      writeThrough: (result) => _writeThroughBudget(result),
    );
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _exec<void>(
      remoteOp: () => remote.deleteBudget(id),
      localOp: () => local.deleteBudget(id),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('delete', 'budgets', {'id': id}),
    );
  }

  @override
  Future<BudgetModel> updateBudget(String id, BudgetModel b) async {
    return _exec(
      remoteOp: () => remote.updateBudget(id, b),
      localOp: () => local.updateBudget(id, b),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('update', 'budgets', b.toJson()),
      writeThrough: (result) => _writeThroughBudget(result),
    );
  }

  @override
  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year) async {
    return _exec(
      remoteOp: () => remote.fetchBudgetsByMonth(month, year),
      localOp: () => local.fetchBudgetsByMonth(month, year),
    );
  }

  @override
  Future<void> updateBudgetSpent(String id, double spent) async {
    await _exec<void>(
      remoteOp: () => remote.updateBudgetSpent(id, spent),
      localOp: () => local.updateBudgetSpent(id, spent),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue(
        'update',
        'budgets',
        {'id': id, 'spent': spent},
      ),
      writeThrough: (_) async {
        final db = await local.database;
        await db.update(
          'budgets',
          {'spent': spent},
          where: 'id = ?',
          whereArgs: [id],
        );
      },
    );
  }

  // ============ CATEGORIES ============

  @override
  Future<List<CategoryModel>> fetchAllCategories() async {
    return _exec(
      remoteOp: () => remote.fetchAllCategories(),
      localOp: () => local.fetchAllCategories(),
    );
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel c) async {
    return _exec(
      remoteOp: () => remote.createCategory(c),
      localOp: () => local.createCategory(c),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('create', 'categories', c.toMap()),
      writeThrough: (_) => _writeThroughCategory(c),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _exec<void>(
      remoteOp: () => remote.deleteCategory(id),
      localOp: () => local.deleteCategory(id),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('delete', 'categories', {'id': id}),
    );
  }

  @override
  Future<CategoryModel> updateCategory(String id, CategoryModel c) async {
    return _exec(
      remoteOp: () => remote.updateCategory(id, c),
      localOp: () => local.updateCategory(id, c),
      isWrite: true,
      queueOp: () => _syncQueue.enqueue('update', 'categories', c.toMap()),
      writeThrough: (_) => _writeThroughCategory(c.copyWith(id: id)),
    );
  }
}
