import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  final int month;
  final int year;
  final double income;
  final double expense;
  final Map<String, double> categoryTotals;
  final List<TransactionModel> transactions;

  const ReportLoaded({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.categoryTotals,
    required this.transactions,
  });

  @override
  List<Object?> get props => [month, year, income, expense, categoryTotals, transactions];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object?> get props => [message];
}
