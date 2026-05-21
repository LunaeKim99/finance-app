import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/smart_db_helper.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final SmartDbHelper _db;

  BudgetRepositoryImpl(this._db);

  @override
  Future<void> initialize() async => _db.initialize();

  @override
  Future<List<Budget>> getBudgets() async {
    final models = await _db.fetchAllBudgets();
    return models.map(_toEntity).toList();
  }

  @override
  Future<void> setBudget(Budget budget) async {
    await _db.createBudget(_toModel(budget));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
  }

  Future<List<Budget>> fetchByMonth(int month, int year) async {
    final models = await _db.fetchBudgetsByMonth(month, year);
    return models.map(_toEntity).toList();
  }

  Future<void> updateSpent(String id, double spent) async {
    await _db.updateBudgetSpent(id, spent);
  }

  Budget _toEntity(BudgetModel m) {
    return Budget(
      id: m.id,
      name: m.name,
      amount: m.amount,
      spent: m.spent,
      category: m.category,
      month: m.month,
      year: m.year,
      note: m.note.isEmpty ? null : m.note,
      isActive: m.isActive,
      currency: m.currency,
    );
  }

  BudgetModel _toModel(Budget e) {
    return BudgetModel(
      id: e.id,
      name: e.name,
      amount: e.amount,
      spent: e.spent,
      category: e.category,
      month: e.month,
      year: e.year,
      note: e.note ?? '',
      isActive: e.isActive,
      currency: e.currency,
    );
  }
}
