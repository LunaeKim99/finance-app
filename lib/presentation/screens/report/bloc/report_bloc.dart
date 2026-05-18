import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../data/report_datasource.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/transaction_type.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportDatasource _datasource;

  ReportBloc({required ReportDatasource datasource})
      : _datasource = datasource,
        super(const ReportInitial()) {
    on<ReportLoadRequested>(_onLoad);
    on<ReportChangeMonth>(_onChangeMonth);
  }

  Future<void> _onLoad(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    try {
      final all = await _datasource.fetchAll();
      _emitLoaded(emit, event.month, event.year, all);
    } catch (e) {
      debugPrint('[ReportBloc] Load error: $e');
      emit(const ReportError(message: 'Gagal memuat laporan'));
    }
  }

  Future<void> _onChangeMonth(
    ReportChangeMonth event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    try {
      final all = await _datasource.fetchAll();
      _emitLoaded(emit, event.month, event.year, all);
    } catch (e) {
      debugPrint('[ReportBloc] Change month error: $e');
      emit(const ReportError(message: 'Gagal mengubah bulan'));
    }
  }

  void _emitLoaded(
    Emitter<ReportState> emit,
    int month,
    int year,
    List<TransactionModel> all,
  ) {
    final filtered = all.where((t) => t.date.month == month && t.date.year == year).toList();
    double income = 0;
    double expense = 0;
    final Map<String, double> categoryTotals = {};

    for (final t in filtered) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        categoryTotals.update(
          t.category,
          (v) => v + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    emit(ReportLoaded(
      month: month,
      year: year,
      income: income,
      expense: expense,
      categoryTotals: categoryTotals,
      transactions: filtered,
    ));
  }
}
