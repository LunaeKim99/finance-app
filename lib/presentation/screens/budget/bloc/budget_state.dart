import 'package:equatable/equatable.dart';
import '../../../../data/models/budget_model.dart';

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
  final List<BudgetModel> budgets;
  final int month;
  final int year;

  const BudgetLoaded({
    required this.budgets,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [budgets, month, year];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError({required this.message});

  @override
  List<Object?> get props => [message];
}
