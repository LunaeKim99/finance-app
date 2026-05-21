import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'export_import_event.dart';
import 'export_import_state.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  final TransactionRepositoryImpl _repository;

  ExportImportBloc()
      : _repository = TransactionRepositoryImpl(
          SmartDbHelper(remote: PbHelper(), local: SqliteHelper()),
        ),
        super(const ExportImportInitial()) {
    on<ExportImportLoadRequested>(_onLoad);
    on<ExportImportExportPdf>(_onExportPdf);
    on<ExportImportExportExcel>(_onExportExcel);
  }

  Future<void> _onLoad(
    ExportImportLoadRequested event,
    Emitter<ExportImportState> emit,
  ) async {
    emit(const ExportImportLoading());
    try {
      final transactions = await _repository.getTransactions();
      final filtered = transactions
          .where((t) => t.date.month == event.month && t.date.year == event.year)
          .toList();
      emit(ExportImportLoaded(
        transactions: filtered,
        month: event.month,
        year: event.year,
        filteredCount: filtered.length,
      ));
    } catch (e) {
      debugPrint('[ExportImportBloc] Load error: $e');
      emit(const ExportImportError(message: 'Gagal memuat data'));
    }
  }

  Future<void> _onExportPdf(
    ExportImportExportPdf event,
    Emitter<ExportImportState> emit,
  ) async {
    emit(const ExportImportExporting(exportType: 'pdf'));
    try {
      final transactions = await _repository.fetchByMonth(event.month, event.year);
      emit(ExportImportLoaded(
        transactions: transactions,
        month: event.month,
        year: event.year,
        filteredCount: transactions.length,
      ));
    } catch (e) {
      debugPrint('[ExportImportBloc] Export PDF error: $e');
      emit(const ExportImportError(message: 'Gagal export PDF'));
    }
  }

  Future<void> _onExportExcel(
    ExportImportExportExcel event,
    Emitter<ExportImportState> emit,
  ) async {
    emit(const ExportImportExporting(exportType: 'excel'));
    try {
      final transactions = await _repository.fetchByMonth(event.month, event.year);
      emit(ExportImportLoaded(
        transactions: transactions,
        month: event.month,
        year: event.year,
        filteredCount: transactions.length,
      ));
    } catch (e) {
      debugPrint('[ExportImportBloc] Export Excel error: $e');
      emit(const ExportImportError(message: 'Gagal export Excel'));
    }
  }
}
