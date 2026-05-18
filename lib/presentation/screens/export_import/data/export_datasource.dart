import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/transaction_model.dart';

class ExportDatasource {
  final SmartDbHelper _dbHelper;

  ExportDatasource(this._dbHelper);

  Future<List<TransactionModel>> fetchAll() => _dbHelper.fetchAllTransactions();

  Future<List<TransactionModel>> fetchByMonth(int month, int year) =>
      _dbHelper.fetchTransactionsByMonth(month, year);
}
