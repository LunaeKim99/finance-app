import 'package:uwangku/data/datasources/db_interface.dart';
import 'package:uwangku/data/models/transaction_model.dart';
import 'package:uwangku/data/models/asset_model.dart';
import 'package:uwangku/data/models/debt_model.dart';
import 'package:uwangku/data/models/budget_model.dart';
import 'package:uwangku/data/models/category_model.dart';

class MockDbHelper implements DbInterface {
  final List<TransactionModel> _transactions = [];
  int _idCounter = 1;

  void clear() => _transactions.clear();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<TransactionModel>> fetchAllTransactions() async =>
      List.from(_transactions.reversed);

  @override
  Future<TransactionModel> createTransaction(TransactionModel t) async {
    final created = t.copyWith(id: 'mock_${_idCounter++}');
    _transactions.add(created);
    return created;
  }

  @override
  Future<TransactionModel> updateTransaction(String id, TransactionModel t) async {
    final index = _transactions.indexWhere((e) => e.id == id);
    if (index == -1) throw Exception('Transaction not found: $id');
    _transactions[index] = t.copyWith(id: id);
    return _transactions[index];
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final lengthBefore = _transactions.length;
    _transactions.removeWhere((e) => e.id == id);
    if (_transactions.length == lengthBefore) {
      throw Exception('Transaction not found: $id');
    }
  }

  @override
  Future<List<TransactionModel>> fetchTransactionsByMonth(int month, int year) async {
    return _transactions.where((t) => t.date.month == month && t.date.year == year).toList();
  }

  @override
  Future<List<AssetModel>> fetchAllAssets() async => [];

  @override
  Future<AssetModel> createAsset(AssetModel a) async => a;

  @override
  Future<void> deleteAsset(String id) async {}

  @override
  Future<AssetModel> updateAsset(String id, AssetModel a) async => a;

  @override
  Future<List<DebtModel>> fetchAllDebts() async => [];

  @override
  Future<DebtModel> createDebt(DebtModel d) async => d;

  @override
  Future<void> deleteDebt(String id) async {}

  @override
  Future<DebtModel> updateDebt(String id, DebtModel d) async => d;

  @override
  Future<List<DebtModel>> fetchUnpaidDebts() async => [];

  @override
  Future<List<BudgetModel>> fetchAllBudgets() async => [];

  @override
  Future<BudgetModel> createBudget(BudgetModel b) async => b;

  @override
  Future<void> deleteBudget(String id) async {}

  @override
  Future<BudgetModel> updateBudget(String id, BudgetModel b) async => b;

  @override
  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year) async => [];

  @override
  Future<void> updateBudgetSpent(String id, double spent) async {}

  @override
  Future<List<CategoryModel>> fetchAllCategories() async => [];

  @override
  Future<CategoryModel> createCategory(CategoryModel c) async => c;

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<CategoryModel> updateCategory(String id, CategoryModel c) async => c;
}