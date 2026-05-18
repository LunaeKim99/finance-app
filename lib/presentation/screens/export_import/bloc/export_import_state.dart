import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';

abstract class ExportImportState extends Equatable {
  const ExportImportState();

  @override
  List<Object?> get props => [];
}

class ExportImportInitial extends ExportImportState {
  const ExportImportInitial();
}

class ExportImportLoading extends ExportImportState {
  const ExportImportLoading();
}

class ExportImportLoaded extends ExportImportState {
  final List<TransactionModel> transactions;
  final int month;
  final int year;
  final int filteredCount;
  final bool isPremium;

  const ExportImportLoaded({
    required this.transactions,
    required this.month,
    required this.year,
    required this.filteredCount,
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [transactions, month, year, filteredCount, isPremium];
}

class ExportImportExporting extends ExportImportState {
  final String exportType;

  const ExportImportExporting({required this.exportType});

  @override
  List<Object?> get props => [exportType];
}

class ExportImportError extends ExportImportState {
  final String message;

  const ExportImportError({required this.message});

  @override
  List<Object?> get props => [message];
}
