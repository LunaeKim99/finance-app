import 'package:equatable/equatable.dart';
import '../../../../domain/entities/budget.dart';

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
  final Budget budget;

  const BudgetAddRequested({required this.budget});

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdateRequested extends BudgetEvent {
  final Budget budget;

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

class BudgetSetRequested extends BudgetEvent {
  final String? id;
  final String name;
  final String category;
  final double amount;
  final int month;
  final int year;
  final String note;

  const BudgetSetRequested({
    this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.note = '',
  });

  @override
  List<Object?> get props => [id, name, category, amount, month, year, note];
}
