import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';
import '../../../../data/datasources/remote/ai_service.dart';
import '../../../../domain/entities/transaction.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final TransactionRepositoryImpl _repository;

  ReportBloc()
      : _repository = TransactionRepositoryImpl(
          SmartDbHelper(remote: PbHelper(), local: SqliteHelper()),
        ),
        super(const ReportInitial()) {
    on<ReportLoadRequested>(_onLoad);
    on<ReportChangeMonth>(_onChangeMonth);
    on<ReportGenerateAiSummary>(_onGenerateAiSummary);
  }

  Future<void> _onLoad(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    try {
      final all = await _repository.getTransactions();
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
      final all = await _repository.getTransactions();
      _emitLoaded(emit, event.month, event.year, all);
    } catch (e) {
      debugPrint('[ReportBloc] Change month error: $e');
      emit(const ReportError(message: 'Gagal mengubah bulan'));
    }
  }

  Future<void> _onGenerateAiSummary(
    ReportGenerateAiSummary event,
    Emitter<ReportState> emit,
  ) async {
    final current = state;
    if (current is! ReportLoaded) return;
    emit(current.copyWith(aiSummaryLoading: true));

    try {
      final summary = await AiRecommendationService().generateBudgetRecommendation(
        categoryTotals: event.categoryTotals,
        totalIncome: event.totalIncome,
        totalExpense: event.totalExpense,
      );
      if (!isClosed) {
        emit(current.copyWith(aiSummary: summary, aiSummaryLoading: false));
      }
    } catch (e) {
      debugPrint('[ReportBloc] AI summary error: $e');
      if (!isClosed) {
        emit(current.copyWith(
          aiSummary: 'Gagal membuat analisis. Coba lagi nanti.',
          aiSummaryLoading: false,
        ));
      }
    }
  }

  void _emitLoaded(
    Emitter<ReportState> emit,
    int month,
    int year,
    List<Transaction> all,
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
