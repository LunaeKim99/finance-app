import 'package:equatable/equatable.dart';
import '../../../../data/models/budget_model.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class BudgetLoadRequested extends BudgetEvent {
  final int month;
  final int year;

  const BudgetLoadRequested({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class BudgetAddRequested extends BudgetEvent {
  final BudgetModel budget;

  const BudgetAddRequested({required this.budget});

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdateRequested extends BudgetEvent {
  final BudgetModel budget;

  const BudgetUpdateRequested({required this.budget});

  @override
  List<Object?> get props => [budget];
}

class BudgetDeleteRequested extends BudgetEvent {
  final String id;

  const BudgetDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}
