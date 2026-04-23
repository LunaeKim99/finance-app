import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/pb_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final PbHelper _pbHelper = PbHelper();
  final Connectivity _connectivity = Connectivity();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;

  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await _pbHelper.initialize();
    await checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    await checkConnectivity();
    if (!_isOnline) {
      _errorMessage = 'Tidak ada koneksi internet';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _pbHelper.fetchAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    await checkConnectivity();
    if (!_isOnline) {
      _errorMessage = 'Tidak ada koneksi internet';
      notifyListeners();
      return false;
    }

    try {
      final newTransaction = await _pbHelper.create(transaction);
      _transactions.insert(0, newTransaction);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    await checkConnectivity();
    if (!_isOnline) {
      _errorMessage = 'Tidak ada koneksi internet';
      notifyListeners();
      return false;
    }

    try {
      await _pbHelper.delete(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    await checkConnectivity();
    if (!_isOnline) {
      _errorMessage = 'Tidak ada koneksi internet';
      notifyListeners();
      return false;
    }

    try {
      final updatedTransaction = await _pbHelper.update(transaction.id!, transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (final t in _transactions) {
      if (t.type == 'income') {
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
            t.type == 'income' &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryTotals(int month, int year) {
    final Map<String, double> categoryTotals = {};
    final filteredTransactions = _transactions.where((t) =>
        t.type == 'expense' &&
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
            t.type == 'income' &&
            t.date.month == month &&
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyExpenseByMonth(int month, int year) {
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.month == month &&
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}