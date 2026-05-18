import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      emit(const DashboardLoaded(
        balance: 0,
        monthlyIncome: 0,
        monthlyExpense: 0,
        isOnline: true,
      ));
    } catch (e) {
      debugPrint('[DashboardBloc] Load error: $e');
      emit(const DashboardError(message: 'Gagal memuat dashboard'));
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    add(const DashboardLoadRequested());
  }
}
