import 'package:pocketbase/pocketbase.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/budget_model.dart';

import '../../services/pb_client.dart';

class PbHelper {
  static PbHelper? _instance;
  late PocketBase _pb;
  bool _isInitialized = false;

  factory PbHelper() {
    _instance ??= PbHelper._internal();
    return _instance!;
  }

  PbHelper._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _pb = PbClient.instance;
    _isInitialized = true;
  }

  PocketBase get pb {
    if (!_isInitialized) {
      _pb = PbClient.instance;
      _isInitialized = true;
    }
    return _pb;
  }

  String? get _userId => _pb.authStore.model?.id;

  // ============ TRANSACTIONS ============
  Future<List<TransactionModel>> fetchAllTransactions() async {
    try {
      final filter = _userId != null ? 'user = "$_userId"' : '';
      final result = await _pb.collection('transactions').getList(
        filter: filter,
        sort: '-date',
      );
      return result.items.map((r) => TransactionModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel t) async {
    try {
      final body = t.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('transactions').create(body: body);
      return TransactionModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _pb.collection('transactions').delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionModel> updateTransaction(String id, TransactionModel t) async {
    try {
      final body = t.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('transactions').update(id, body: body);
      return TransactionModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> fetchTransactionsByMonth(int month, int year) async {
    try {
      final endDate = DateTime(year, month + 1, 0);
      final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
      final endStr = '$year-${month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final filter = 'date >= "$startStr" && date <= "$endStr"';
      final userFilter = _userId != null ? ' && user = "$_userId"' : '';

      final result = await _pb.collection('transactions').getList(
        filter: filter + userFilter,
        sort: '-date',
      );
      return result.items.map((r) => TransactionModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ============ ASSETS ============
  Future<List<AssetModel>> fetchAllAssets() async {
    try {
      final filter = _userId != null ? 'user = "$_userId"' : '';
      final result = await _pb.collection('assets').getList(
        filter: filter,
        sort: '-created',
      );
      return result.items.map((r) => AssetModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<AssetModel> createAsset(AssetModel a) async {
    try {
      final body = a.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('assets').create(body: body);
      return AssetModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _pb.collection('assets').delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<AssetModel> updateAsset(String id, AssetModel a) async {
    try {
      final body = a.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('assets').update(id, body: body);
      return AssetModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  // ============ DEBTS ============
  Future<List<DebtModel>> fetchAllDebts() async {
    try {
      final filter = _userId != null ? 'user = "$_userId"' : '';
      final result = await _pb.collection('debts').getList(
        filter: filter,
        sort: '-created',
      );
      return result.items.map((r) => DebtModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<DebtModel> createDebt(DebtModel d) async {
    try {
      final body = d.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('debts').create(body: body);
      return DebtModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _pb.collection('debts').delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<DebtModel> updateDebt(String id, DebtModel d) async {
    try {
      final body = d.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('debts').update(id, body: body);
      return DebtModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DebtModel>> fetchUnpaidDebts() async {
    try {
      final filter = 'is_paid = false';
      final userFilter = _userId != null ? ' && user = "$_userId"' : '';
      final result = await _pb.collection('debts').getList(
        filter: filter + userFilter,
        sort: '-created',
      );
      return result.items.map((r) => DebtModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ============ BUDGETS ============
  Future<List<BudgetModel>> fetchAllBudgets() async {
    try {
      final filter = _userId != null ? 'user = "$_userId"' : '';
      final result = await _pb.collection('budgets').getList(
        filter: filter,
        sort: '-year, -month',
      );
      return result.items.map((r) => BudgetModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<BudgetModel> createBudget(BudgetModel b) async {
    try {
      final body = b.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('budgets').create(body: body);
      return BudgetModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _pb.collection('budgets').delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<BudgetModel> updateBudget(String id, BudgetModel b) async {
    try {
      final body = b.toJson();
      if (_userId != null) body['user'] = _userId;
      final result = await _pb.collection('budgets').update(id, body: body);
      return BudgetModel.fromRecord(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year) async {
    try {
      final filter = 'month = $month && year = $year';
      final userFilter = _userId != null ? ' && user = "$_userId"' : '';
      final result = await _pb.collection('budgets').getList(
        filter: filter + userFilter,
        sort: '-created',
      );
      return result.items.map((r) => BudgetModel.fromRecord(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBudgetSpent(String id, double spent) async {
    try {
      await _pb.collection('budgets').update(id, body: {'spent': spent});
    } catch (e) {
      rethrow;
    }
  }

}
