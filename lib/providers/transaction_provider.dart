import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getAllTransactions();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final id = await _dbHelper.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      _transactions.insert(0, newTransaction);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _dbHelper.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await _dbHelper.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
      return true;
    } catch (e) {
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