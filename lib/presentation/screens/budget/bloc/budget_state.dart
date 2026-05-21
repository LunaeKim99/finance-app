import 'package:equatable/equatable.dart';
import '../../../../domain/entities/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final int month;
  final int year;

  const BudgetLoaded({
    required this.budgets,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [budgets, month, year];

  Budget? getBudgetForCategory(String category) {
    try {
      return budgets.firstWhere(
        (b) => b.category == category && b.month == month && b.year == year && b.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  List<Budget> getBudgetsForMonth(int m, int y) {
    return budgets.where((b) => b.month == m && b.year == y && b.isActive).toList();
  }

  double getBudgetUsagePercent(String category, double spent) {
    final budget = getBudgetForCategory(category);
    if (budget == null || budget.amount <= 0) return 0;
    return (spent / budget.amount) * 100;
  }

  bool isOverBudget(String category, double spent) {
    return getBudgetUsagePercent(category, spent) >= 100;
  }

  bool isWarningBudget(String category, double spent) {
    final percent = getBudgetUsagePercent(category, spent);
    return percent >= 80 && percent < 100;
  }

  List<Map<String, dynamic>> getBudgetSummary(Map<String, double> categoryTotals) {
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

    summary.sort((a, b) => (b['percent'] as double).compareTo(a['percent'] as double));
    return summary;
  }
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError({required this.message});

  @override
  List<Object?> get props => [message];
}
