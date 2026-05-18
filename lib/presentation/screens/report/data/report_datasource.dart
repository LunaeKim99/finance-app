import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/transaction_model.dart';

class ReportDatasource {
  final SmartDbHelper _dbHelper;

  ReportDatasource(this._dbHelper);

  Future<List<TransactionModel>> fetchAll() => _dbHelper.fetchAllTransactions();

  Future<List<TransactionModel>> fetchByMonth(int month, int year) =>
      _dbHelper.fetchTransactionsByMonth(month, year);
}
