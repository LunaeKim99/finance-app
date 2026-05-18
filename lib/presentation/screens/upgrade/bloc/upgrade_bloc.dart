import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'upgrade_event.dart';
import 'upgrade_state.dart';

class UpgradeBloc extends Bloc<UpgradeEvent, UpgradeState> {
  UpgradeBloc() : super(const UpgradeInitial()) {
    on<UpgradeProcessPayment>(_onProcessPayment);
    on<UpgradeSelectPlan>(_onSelectPlan);
  }

  Future<void> _onProcessPayment(
    UpgradeProcessPayment event,
    Emitter<UpgradeState> emit,
  ) async {
    emit(const UpgradeLoading(message: 'Memproses pembayaran...'));
    try {
      emit(const UpgradeSuccess());
    } catch (e) {
      debugPrint('[UpgradeBloc] Error: $e');
      emit(UpgradeError(message: 'Pembayaran gagal: $e'));
    }
  }

  Future<void> _onSelectPlan(
    UpgradeSelectPlan event,
    Emitter<UpgradeState> emit,
  ) async {
    emit(const UpgradeInitial());
  }
}
