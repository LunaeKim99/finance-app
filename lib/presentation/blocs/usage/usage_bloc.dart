import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'usage_event.dart';
import 'usage_state.dart';
import '../../../domain/repositories/usage_repository.dart';

class UsageBloc extends Bloc<UsageEvent, UsageState> {
  final UsageRepository _usageRepository;

  UsageBloc({required UsageRepository usageRepository})
      : _usageRepository = usageRepository,
        super(const UsageInitial()) {
    on<UsageLoadRequested>(_onLoad);
    on<UsageIncrementAiText>(_onIncrementAiText);
    on<UsageIncrementAiPhoto>(_onIncrementAiPhoto);
    on<UsageUpgradeToPremium>(_onUpgrade);
    on<UsageDowngradeToFree>(_onDowngrade);
  }

  Future<void> _onLoad(
    UsageLoadRequested event,
    Emitter<UsageState> emit,
  ) async {
    emit(const UsageLoading());
    try {
      final usage = await _usageRepository.load();
      emit(UsageLoaded(usage: usage));
    } catch (e) {
      debugPrint('[UsageBloc] Load error: $e');
      emit(const UsageError(message: 'Gagal memuat usage'));
    }
  }

  Future<void> _onIncrementAiText(
    UsageIncrementAiText event,
    Emitter<UsageState> emit,
  ) async {
    final current = state;
    if (current is UsageLoaded) {
      if (current.usage.isPremium) return;
      final updated = current.usage.copyWith(
        aiTextUsedToday: current.usage.aiTextUsedToday + 1,
      );
      await _usageRepository.save(updated);
      emit(UsageLoaded(usage: updated));
    }
  }

  Future<void> _onIncrementAiPhoto(
    UsageIncrementAiPhoto event,
    Emitter<UsageState> emit,
  ) async {
    final current = state;
    if (current is UsageLoaded) {
      if (current.usage.isPremium) return;
      final updated = current.usage.copyWith(
        aiPhotoUsedToday: current.usage.aiPhotoUsedToday + 1,
      );
      await _usageRepository.save(updated);
      emit(UsageLoaded(usage: updated));
    }
  }

  Future<void> _onUpgrade(
    UsageUpgradeToPremium event,
    Emitter<UsageState> emit,
  ) async {
    final current = state;
    if (current is UsageLoaded) {
      final updated = current.usage.copyWith(isPremium: true);
      await _usageRepository.save(updated);
      emit(UsageLoaded(usage: updated));
    }
  }

  Future<void> _onDowngrade(
    UsageDowngradeToFree event,
    Emitter<UsageState> emit,
  ) async {
    final current = state;
    if (current is UsageLoaded) {
      final updated = current.usage.copyWith(isPremium: false);
      await _usageRepository.save(updated);
      emit(UsageLoaded(usage: updated));
    }
  }
}
