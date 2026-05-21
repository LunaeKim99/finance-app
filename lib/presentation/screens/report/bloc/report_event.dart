import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {
  final int month;
  final int year;

  const ReportLoadRequested({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class ReportChangeMonth extends ReportEvent {
  final int month;
  final int year;

  const ReportChangeMonth({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

class ReportGenerateAiSummary extends ReportEvent {
  final Map<String, double> categoryTotals;
  final double totalIncome;
  final double totalExpense;

  const ReportGenerateAiSummary({
    required this.categoryTotals,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  List<Object?> get props => [categoryTotals, totalIncome, totalExpense];
}
