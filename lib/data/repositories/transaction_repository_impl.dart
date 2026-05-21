import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/smart_db_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart' as data;

class TransactionRepositoryImpl implements TransactionRepository {
  final SmartDbHelper _db;

  TransactionRepositoryImpl(this._db);

  @override
  Future<void> initialize() async => _db.initialize();

  @override
  Future<List<Transaction>> getTransactions() async {
    final models = await _db.fetchAllTransactions();
    return models.map(_toEntity).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _db.createTransaction(_toModel(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction.safeId, _toModel(transaction));
  }

  Future<List<Transaction>> fetchByMonth(int month, int year) async {
    final models = await _db.fetchTransactionsByMonth(month, year);
    return models.map(_toEntity).toList();
  }

  Transaction _toEntity(TransactionModel m) {
    return Transaction(
      id: m.id,
      title: m.title,
      amount: m.amount,
      type: m.type == data.TransactionType.income
          ? TransactionType.income
          : TransactionType.expense,
      category: m.categoryId,
      date: m.date,
      note: m.note.isEmpty ? null : m.note,
      isSynced: m.isSynced,
      currency: m.currency,
      exchangeRateToIdr: m.exchangeRateToIdr,
    );
  }

  TransactionModel _toModel(Transaction e) {
    return TransactionModel(
      id: e.id,
      title: e.title,
      amount: e.amount,
      type: e.type == TransactionType.income
          ? data.TransactionType.income
          : data.TransactionType.expense,
      categoryId: e.category,
      date: e.date,
      note: e.note ?? '',
      isSynced: e.isSynced,
      currency: e.currency,
      exchangeRateToIdr: e.exchangeRateToIdr,
    );
  }
}
