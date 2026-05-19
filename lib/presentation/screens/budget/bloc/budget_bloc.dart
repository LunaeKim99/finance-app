import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'budget_event.dart';
import 'budget_state.dart';
import '../data/budget_datasource.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';
import '../../../../data/models/budget_model.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  late final BudgetDatasource _datasource;
  late final SmartDbHelper _dbHelper;
  bool _initialized = false;

  BudgetBloc() : super(const BudgetInitial()) {
    _dbHelper = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());
    _datasource = BudgetDatasource(dbHelper: _dbHelper);
    on<BudgetLoadRequested>(_onLoadBudgets);
    on<BudgetAddRequested>(_onAddBudget);
    on<BudgetUpdateRequested>(_onUpdateBudget);
    on<BudgetDeleteRequested>(_onDeleteBudget);
    on<BudgetSetRequested>(_onSetBudget);
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _dbHelper.initialize();
  }

  Future<void> _onLoadBudgets(
    BudgetLoadRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading());
    try {
      final budgets = await _datasource.fetchByMonth(event.month, event.year);
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
      await _datasource.create(event.budget);
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
      await _datasource.update(event.budget.id ?? '', event.budget);
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
      await _datasource.delete(event.id);
      final current = state;
      if (current is BudgetLoaded) {
        add(BudgetLoadRequested(month: current.month, year: current.year));
      }
    } catch (e) {
      debugPrint('[BudgetBloc] Delete error: $e');
      emit(const BudgetError(message: 'Gagal menghapus budget'));
    }
  }

  Future<void> _onSetBudget(
    BudgetSetRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      if (event.id != null && event.id!.isNotEmpty) {
        final updated = BudgetModel(
          id: event.id,
          name: event.name,
          amount: event.amount,
          category: event.category,
          month: event.month,
          year: event.year,
          note: event.note,
          currency: 'IDR',
        );
        await _datasource.update(event.id!, updated);
      } else {
        final budget = BudgetModel(
          name: event.name,
          amount: event.amount,
          category: event.category,
          month: event.month,
          year: event.year,
          note: event.note,
          currency: 'IDR',
        );
        await _datasource.create(budget);
      }
      final current = state;
      if (current is BudgetLoaded) {
        add(BudgetLoadRequested(month: current.month, year: current.year));
      }
    } catch (e) {
      debugPrint('[BudgetBloc] Set budget error: $e');
      emit(const BudgetError(message: 'Gagal menyimpan budget'));
    }
  }
}
