import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'budget_event.dart';
import 'budget_state.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  late final SmartDbHelper _dbHelper;

  BudgetBloc() : super(const BudgetInitial()) {
    _dbHelper = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());
    on<BudgetLoadRequested>(_onLoadBudgets);
    on<BudgetAddRequested>(_onAddBudget);
    on<BudgetUpdateRequested>(_onUpdateBudget);
    on<BudgetDeleteRequested>(_onDeleteBudget);
  }

  SmartDbHelper get dbHelper => _dbHelper;

  Future<void> initialize() async {
    await _dbHelper.initialize();
  }

  Future<void> _onLoadBudgets(
    BudgetLoadRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading());
    try {
      final budgets = await _dbHelper.fetchBudgetsByMonth(event.month, event.year);
      emit(BudgetLoaded(
        budgets: budgets,
        month: event.month,
        year: event.year,
      ));
    } catch (e) {
      debugPrint('[BudgetBloc] Load error: $e');
      emit(const BudgetError(message: 'Gagal memuat budget'));
    }
  }

  Future<void> _onAddBudget(
    BudgetAddRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _dbHelper.createBudget(event.budget);
      final current = state;
      if (current is BudgetLoaded) {
        add(BudgetLoadRequested(month: current.month, year: current.year));
      }
    } catch (e) {
      debugPrint('[BudgetBloc] Add error: $e');
      emit(const BudgetError(message: 'Gagal menambah budget'));
    }
  }

  Future<void> _onUpdateBudget(
    BudgetUpdateRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _dbHelper.updateBudget(event.budget.id ?? '', event.budget);
      final current = state;
      if (current is BudgetLoaded) {
        add(BudgetLoadRequested(month: current.month, year: current.year));
      }
    } catch (e) {
      debugPrint('[BudgetBloc] Update error: $e');
      emit(const BudgetError(message: 'Gagal mengupdate budget'));
    }
  }

  Future<void> _onDeleteBudget(
    BudgetDeleteRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _dbHelper.deleteBudget(event.id);
      final current = state;
      if (current is BudgetLoaded) {
        add(BudgetLoadRequested(month: current.month, year: current.year));
      }
    } catch (e) {
      debugPrint('[BudgetBloc] Delete error: $e');
      emit(const BudgetError(message: 'Gagal menghapus budget'));
    }
  }
}
