import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/budget_model.dart';

class DashboardDatasource {
  final SmartDbHelper _dbHelper;

  DashboardDatasource(this._dbHelper);

  Future<List<TransactionModel>> fetchAllTransactions() =>
      _dbHelper.fetchAllTransactions();

  Future<List<BudgetModel>> fetchAllBudgets() => _dbHelper.fetchAllBudgets();
}
