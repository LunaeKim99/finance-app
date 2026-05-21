import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'budget_event.dart';
import 'budget_state.dart';
import '../../../../data/repositories/budget_repository_impl.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';
import '../../../../domain/entities/budget.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  late final BudgetRepositoryImpl _repository;

  BudgetBloc() : super(const BudgetInitial()) {
    final db = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());
    _repository = BudgetRepositoryImpl(db);
    on<BudgetLoadRequested>(_onLoadBudgets);
    on<BudgetAddRequested>(_onAddBudget);
    on<BudgetUpdateRequested>(_onUpdateBudget);
    on<BudgetDeleteRequested>(_onDeleteBudget);
    on<BudgetSetRequested>(_onSetBudget);
  }

  Future<void> ensureInitialized() async {}

  Future<void> _onLoadBudgets(
    BudgetLoadRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading());
    try {
      final budgets = await _repository.fetchByMonth(event.month, event.year);
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
      await _repository.setBudget(event.budget);
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
      // update via setBudget since it handles both create/update
      await _repository.setBudget(event.budget);
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
      await _repository.deleteBudget(event.id);
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
      final budget = Budget(
        id: event.id,
        name: event.name,
        amount: event.amount,
        category: event.category,
        month: event.month,
        year: event.year,
        note: event.note.isEmpty ? null : event.note,
        currency: 'IDR',
      );
      await _repository.setBudget(budget);
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
