import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';

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
  final List<Transaction> transactions;
  final String? aiSummary;
  final bool aiSummaryLoading;

  const ReportLoaded({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.categoryTotals,
    required this.transactions,
    this.aiSummary,
    this.aiSummaryLoading = false,
  });

  ReportLoaded copyWith({
    int? month,
    int? year,
    double? income,
    double? expense,
    Map<String, double>? categoryTotals,
    List<Transaction>? transactions,
    String? aiSummary,
    bool? aiSummaryLoading,
  }) {
    return ReportLoaded(
      month: month ?? this.month,
      year: year ?? this.year,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      transactions: transactions ?? this.transactions,
      aiSummary: aiSummary ?? this.aiSummary,
      aiSummaryLoading: aiSummaryLoading ?? this.aiSummaryLoading,
    );
  }

  @override
  List<Object?> get props => [month, year, income, expense, categoryTotals, transactions, aiSummary, aiSummaryLoading];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object?> get props => [message];
}
