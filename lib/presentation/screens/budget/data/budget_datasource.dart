import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/budget_model.dart';

class BudgetDatasource {
  final SmartDbHelper _dbHelper;

  BudgetDatasource(this._dbHelper);

  Future<List<BudgetModel>> fetchAll() => _dbHelper.fetchAllBudgets();

  Future<List<BudgetModel>> fetchByMonth(int month, int year) =>
      _dbHelper.fetchBudgetsByMonth(month, year);

  Future<BudgetModel> create(BudgetModel b) => _dbHelper.createBudget(b);

  Future<BudgetModel> update(String id, BudgetModel b) =>
      _dbHelper.updateBudget(id, b);

  Future<void> delete(String id) => _dbHelper.deleteBudget(id);

  Future<void> updateSpent(String id, double spent) =>
      _dbHelper.updateBudgetSpent(id, spent);
}
