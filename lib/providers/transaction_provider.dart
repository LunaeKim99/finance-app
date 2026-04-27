import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/db_interface.dart';
import '../database/sqlite_helper.dart';
import '../database/sync_queue_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class TransactionProvider extends ChangeNotifier {
  DbInterface _dbHelper = SqliteHelper();
  final Connectivity _connectivity = Connectivity();
  final SyncQueueHelper _syncQueue = SyncQueueHelper();
  
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  final bool _isSyncing = false;
  bool _isUsingRemoteStorage = false;

  void Function(String message)? onError;
  void Function(String message)? onSuccess;

  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get isUsingRemoteStorage => _isUsingRemoteStorage;

  Future<void> initialize() async {
    await _dbHelper.initialize();
    await checkConnectivity();
    await _loadFromQueue();
  }

  void setUseRemoteStorage(bool value) {
    _isUsingRemoteStorage = value;
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  void switchStorage(DbInterface newStorage) {
    _dbHelper = newStorage;
    _isUsingRemoteStorage = newStorage is! SqliteHelper;
    initialize();
  }

  Future<void> _loadFromQueue() async {
    final pending = await _syncQueue.getPendingItems();
    for (final item in pending) {
      if (item['collection'] == 'transactions') {
        try {
          final payload = _parsePayload(item['payload'] as String);
          final id = 'local_${item['id']}';
          final transaction = TransactionModel.fromMap(payload);
          final localTransaction = transaction.copyWith(id: id, isSynced: false);
          
          final existingIndex = _transactions.indexWhere((t) => t.id == id);
          if (existingIndex == -1) {
            _transactions.insert(0, localTransaction);
          }
        } catch (e) {
          debugPrint('[TransactionProvider] Error loading from queue: $e');
        }
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> _parsePayload(String payloadStr) {
    try {
      final cleanStr = payloadStr
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(' ', '');
      
      final Map<String, dynamic> result = {};
      final pairs = cleanStr.split(',');
      for (final pair in pairs) {
        final kv = pair.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim();
          var value = kv[1].trim();
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          }
          result[key] = value;
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<bool> _requiresOnline() async {
    if (_dbHelper is SqliteHelper || !_isUsingRemoteStorage) {
      _isOnline = true;
      return true;
    }
    await checkConnectivity();
    if (!_isOnline) {
      return false;
    }
    return true;
  }

  void _setError(String message) {
    _errorMessage = message;
    onError?.call(message);
    notifyListeners();
  }

  void _setSuccess(String message) {
    onSuccess?.call(message);
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isUsingRemoteStorage && !await _requiresOnline()) {
        await _loadFromQueue();
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _transactions = await _dbHelper.fetchAllTransactions();
      
      await _loadFromQueue();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    if (_isUsingRemoteStorage && !await _requiresOnline()) {
      await _queueTransaction('create', transaction);
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final localTransaction = transaction.copyWith(id: tempId, isSynced: false);
      _transactions.insert(0, localTransaction);
      _setSuccess('Transaksi disimpan (offline, akan sync nanti)');
      notifyListeners();
      return true;
    }

    try {
      final newTransaction = await _dbHelper.createTransaction(transaction);
      _transactions.insert(0, newTransaction);
      _setSuccess('Transaksi berhasil ditambahkan');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }

  Future<void> _queueTransaction(String operation, TransactionModel transaction) async {
    final payload = transaction.toMap();
    payload['id'] = transaction.id ?? '';
    await _syncQueue.enqueue(operation, 'transactions', payload);
  }

  Future<bool> deleteTransaction(String id) async {
    if (_isUsingRemoteStorage && !await _requiresOnline()) {
      final transaction = _transactions.firstWhere((t) => t.id == id);
      await _queueTransaction('delete', transaction);
      _transactions.removeWhere((t) => t.id == id);
      _setSuccess('Transaksi dihapus (offline, akan sync nanti)');
      notifyListeners();
      return true;
    }

    try {
      await _dbHelper.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _setSuccess('Transaksi berhasil dihapus');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    if (_isUsingRemoteStorage && !await _requiresOnline()) {
      await _queueTransaction('update', transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction.copyWith(isSynced: false);
        _setSuccess('Transaksi diperbarui (offline, akan sync nanti)');
        notifyListeners();
      }
      return true;
    }

    try {
      final transactionId = transaction.safeId;
      if (transactionId.isEmpty) {
        _setError('Transaction ID is required for update');
        return false;
      }
      final updatedTransaction = await _dbHelper.updateTransaction(transactionId, transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _setSuccess('Transaksi berhasil diperbarui');
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  void markTransactionSynced(String? id) {
    if (id == null) return;
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(isSynced: true);
      notifyListeners();
    }
  }

  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return income - expense;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryTotals(int month, int year) {
    final Map<String, double> categoryTotals = {};
    final filteredTransactions = _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.month == month &&
        t.date.year == year);

    for (final t in filteredTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    return categoryTotals;
  }

  List<TransactionModel> getRecentTransactions(int limit) {
    return _transactions.take(limit).toList();
  }

  double getMonthlyIncomeByMonth(int month, int year) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == month &&
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyExpenseByMonth(int month, int year) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == month &&
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}