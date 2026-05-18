import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'export_import_event.dart';
import 'export_import_state.dart';
import '../data/export_datasource.dart';

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  final ExportDatasource _datasource;

  ExportImportBloc({required ExportDatasource datasource})
      : _datasource = datasource,
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
      final transactions = await _datasource.fetchAll();
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
      final transactions = await _datasource.fetchByMonth(event.month, event.year);
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
      final transactions = await _datasource.fetchByMonth(event.month, event.year);
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
