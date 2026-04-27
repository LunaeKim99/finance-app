import 'package:pocketbase/pocketbase.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../models/asset_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import '../services/pb_client.dart';

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

  PocketBase get pb => _pb;

  TransactionModel _recordToTransaction(RecordModel record) {
    return TransactionModel(
      id: record.id,
      title: record.data['title'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      type: TransactionType.fromString(record.data['type'] as String),
      category: record.data['category'] as String,
      date: DateTime.parse(record.data['date'] as String),
      note: (record.data['note'] as String?) ?? '',
    );
  }

  AssetModel _recordToAsset(RecordModel record) {
    return AssetModel(
      id: record.id,
      name: record.data['name'] as String,
      type: record.data['type'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      currency: (record.data['currency'] as String?) ?? 'IDR',
      purchaseDate: record.data['purchase_date'] != null
          ? DateTime.parse(record.data['purchase_date'] as String)
          : null,
      note: (record.data['note'] as String?) ?? '',
      isActive: (record.data['is_active'] as bool?) ?? true,
    );
  }

  DebtModel _recordToDebt(RecordModel record) {
    return DebtModel(
      id: record.id,
      title: record.data['title'] as String,
      type: record.data['type'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      remainingAmount: record.data['remaining_amount'] != null
          ? (record.data['remaining_amount'] as num).toDouble()
          : null,
      personName: (record.data['person_name'] as String?) ?? '',
      dueDate: record.data['due_date'] != null
          ? DateTime.parse(record.data['due_date'] as String)
          : null,
      startDate: record.data['start_date'] != null
          ? DateTime.parse(record.data['start_date'] as String)
          : null,
      isPaid: (record.data['is_paid'] as bool?) ?? false,
      note: (record.data['note'] as String?) ?? '',
    );
  }

  BudgetModel _recordToBudget(RecordModel record) {
    return BudgetModel(
      id: record.id,
      name: record.data['name'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      spent: (record.data['spent'] as num?)?.toDouble() ?? 0,
      category: (record.data['category'] as String?) ?? '',
      month: record.data['month'] as int,
      year: record.data['year'] as int,
      note: (record.data['note'] as String?) ?? '',
      isActive: (record.data['is_active'] as bool?) ?? true,
    );
  }

  // ============ TRANSACTIONS ============
  Future<List<TransactionModel>> fetchAllTransactions() async {
    try {
      final result = await _pb.collection('transactions').getList(sort: '-date');
      return result.items.map((record) => _recordToTransaction(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data: ${e.toString()}');
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel t) async {
    try {
      final result = await _pb.collection('transactions').create(body: t.toJson());
      return _recordToTransaction(result);
    } catch (e) {
      throw Exception('Gagal membuat transaksi: ${e.toString()}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _pb.collection('transactions').delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: ${e.toString()}');
    }
  }

  Future<TransactionModel> updateTransaction(String id, TransactionModel t) async {
    try {
      final result = await _pb.collection('transactions').update(id, body: t.toJson());
      return _recordToTransaction(result);
    } catch (e) {
      throw Exception('Gagal mengupdate transaksi: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> fetchTransactionsByMonth(int month, int year) async {
    try {
      final endDate = DateTime(year, month + 1, 0);
      final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
      final endStr = '$year-${month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final result = await _pb.collection('transactions').getList(
        filter: 'date >= "$startStr" && date <= "$endStr"',
        sort: '-date',
      );
      return result.items.map((record) => _recordToTransaction(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data bulan: ${e.toString()}');
    }
  }

  // ============ ASSETS ============
  Future<List<AssetModel>> fetchAllAssets() async {
    try {
      final result = await _pb.collection('assets').getList(sort: '-created');
      return result.items.map((record) => _recordToAsset(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data aset: ${e.toString()}');
    }
  }

  Future<AssetModel> createAsset(AssetModel a) async {
    try {
      final result = await _pb.collection('assets').create(body: a.toJson());
      return _recordToAsset(result);
    } catch (e) {
      throw Exception('Gagal membuat aset: ${e.toString()}');
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _pb.collection('assets').delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus aset: ${e.toString()}');
    }
  }

  Future<AssetModel> updateAsset(String id, AssetModel a) async {
    try {
      final result = await _pb.collection('assets').update(id, body: a.toJson());
      return _recordToAsset(result);
    } catch (e) {
      throw Exception('Gagal mengupdate aset: ${e.toString()}');
    }
  }

  // ============ DEBTS ============
  Future<List<DebtModel>> fetchAllDebts() async {
    try {
      final result = await _pb.collection('debts').getList(sort: '-created');
      return result.items.map((record) => _recordToDebt(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data hutang/piutang: ${e.toString()}');
    }
  }

  Future<DebtModel> createDebt(DebtModel d) async {
    try {
      final result = await _pb.collection('debts').create(body: d.toJson());
      return _recordToDebt(result);
    } catch (e) {
      throw Exception('Gagal membuat hutang/piutang: ${e.toString()}');
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _pb.collection('debts').delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus hutang/piutang: ${e.toString()}');
    }
  }

  Future<DebtModel> updateDebt(String id, DebtModel d) async {
    try {
      final result = await _pb.collection('debts').update(id, body: d.toJson());
      return _recordToDebt(result);
    } catch (e) {
      throw Exception('Gagal mengupdate hutang/piutang: ${e.toString()}');
    }
  }

  Future<List<DebtModel>> fetchUnpaidDebts() async {
    try {
      final result = await _pb.collection('debts').getList(
        filter: 'is_paid = false',
        sort: '-created',
      );
      return result.items.map((record) => _recordToDebt(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data hutang/piutang: ${e.toString()}');
    }
  }

  // ============ BUDGETS ============
  Future<List<BudgetModel>> fetchAllBudgets() async {
    try {
      final result = await _pb.collection('budgets').getList(sort: '-year, -month');
      return result.items.map((record) => _recordToBudget(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data budget: ${e.toString()}');
    }
  }

  Future<BudgetModel> createBudget(BudgetModel b) async {
    try {
      final result = await _pb.collection('budgets').create(body: b.toJson());
      return _recordToBudget(result);
    } catch (e) {
      throw Exception('Gagal membuat budget: ${e.toString()}');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _pb.collection('budgets').delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus budget: ${e.toString()}');
    }
  }

  Future<BudgetModel> updateBudget(String id, BudgetModel b) async {
    try {
      final result = await _pb.collection('budgets').update(id, body: b.toJson());
      return _recordToBudget(result);
    } catch (e) {
      throw Exception('Gagal mengupdate budget: ${e.toString()}');
    }
  }

  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year) async {
    try {
      final result = await _pb.collection('budgets').getList(
        filter: 'month = $month && year = $year',
        sort: '-created',
      );
      return result.items.map((record) => _recordToBudget(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data budget: ${e.toString()}');
    }
  }

  Future<void> updateBudgetSpent(String id, double spent) async {
    try {
      await _pb.collection('budgets').update(id, body: {'spent': spent});
    } catch (e) {
      throw Exception('Gagal update spent budget: ${e.toString()}');
    }
  }
}