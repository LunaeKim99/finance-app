import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/transaction_model.dart';

class TransactionDatasource {
  final SmartDbHelper _dbHelper;

  TransactionDatasource(this._dbHelper);

  Future<List<TransactionModel>> fetchAll() => _dbHelper.fetchAllTransactions();

  Future<List<TransactionModel>> fetchByMonth(int month, int year) =>
      _dbHelper.fetchTransactionsByMonth(month, year);

  Future<TransactionModel> create(TransactionModel t) =>
      _dbHelper.createTransaction(t);

  Future<TransactionModel> update(String id, TransactionModel t) =>
      _dbHelper.updateTransaction(id, t);

  Future<void> delete(String id) => _dbHelper.deleteTransaction(id);

  bool get isOnline => _dbHelper.isRemoteAvailable;
}
