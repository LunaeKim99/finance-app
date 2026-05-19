import 'package:flutter/foundation.dart';
import '../../data/datasources/db_interface.dart';
import '../../data/datasources/smart_db_helper.dart';
import '../../data/datasources/pb_helper.dart';
import '../../data/datasources/local/sqlite_helper.dart';
import '../../data/models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  late final DbInterface _dbHelper = SmartDbHelper(
    remote: PbHelper(),
    local: SqliteHelper(),
  );
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    await _dbHelper.initialize();
    await loadBudgets();
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _budgets = await _dbHelper.fetchAllBudgets();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setBudget({
    String? id,
    required String name,
    required String category,
    required double amount,
    required int month,
    required int year,
    String note = '',
  }) async {
    try {
      if (id != null && id.isNotEmpty) {
        final updated = BudgetModel(
          id: id,
          name: name,
          amount: amount,
          category: category,
          month: month,
          year: year,
          note: note,
          currency: 'IDR',
        );
        await _dbHelper.updateBudget(id, updated);
      } else {
        final budget = BudgetModel(
          name: name,
          amount: amount,
          category: category,
          month: month,
          year: year,
          note: note,
          currency: 'IDR',
        );
        await _dbHelper.createBudget(budget);
      }
      await loadBudgets();
      return true;
    } catch (e) {
      debugPrint('Error saving budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _dbHelper.deleteBudget(id);
      await loadBudgets();
      return true;
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  BudgetModel? getBudgetForCategory(String category, int month, int year) {
    try {
      return _budgets.firstWhere(
        (b) =>
            b.category == category &&
            b.month == month &&
            b.year == year &&
            b.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  List<BudgetModel> getBudgetsForMonth(int month, int year) {
    return _budgets
        .where((b) => b.month == month && b.year == year && b.isActive)
        .toList();
  }

  double getBudgetUsagePercent(
    String category,
    int month,
    int year,
    double spent,
  ) {
    final budget = getBudgetForCategory(category, month, year);
    if (budget == null || budget.amount <= 0) return 0;
    return (spent / budget.amount) * 100;
  }

  bool isOverBudget(String category, int month, int year, double spent) {
    return getBudgetUsagePercent(category, month, year, spent) >= 100;
  }

  bool isWarningBudget(String category, int month, int year, double spent) {
    final percent = getBudgetUsagePercent(category, month, year, spent);
    return percent >= 80 && percent < 100;
  }

  List<Map<String, dynamic>> getBudgetSummary(
    int month,
    int year,
    Map<String, double> categoryTotals,
  ) {
    final monthBudgets = getBudgetsForMonth(month, year);
    final summary = <Map<String, dynamic>>[];

    for (final budget in monthBudgets) {
      final spent = categoryTotals[budget.category] ?? 0;
      summary.add({
        'category': budget.category,
        'budget': budget.amount,
        'spent': spent,
        'remaining': budget.amount - spent,
        'percent': budget.amount > 0 ? (spent / budget.amount) * 100 : 0,
        'isOverBudget': spent >= budget.amount,
        'isWarning': spent >= budget.amount * 0.8 && spent < budget.amount,
      });
    }

    summary
        .sort((a, b) => (b['percent'] as double).compareTo(a['percent'] as double));
    return summary;
  }
}
