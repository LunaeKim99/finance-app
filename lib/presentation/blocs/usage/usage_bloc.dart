import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_event.dart';
import 'usage_state.dart';
import '../../../data/models/usage_model.dart';

class UsageBloc extends Bloc<UsageEvent, UsageState> {
  static const String _keyAiText = 'usage_ai_text';
  static const String _keyAiPhoto = 'usage_ai_photo';
  static const String _keyIsPremium = 'usage_is_premium';
  static const String _keyLastReset = 'usage_last_reset';

  UsageBloc() : super(const UsageInitial()) {
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
      final prefs = await SharedPreferences.getInstance();

      final lastResetStr = prefs.getString(_keyLastReset);
      DateTime lastReset;
      if (lastResetStr != null) {
        lastReset = DateTime.parse(lastResetStr);
      } else {
        lastReset = DateTime.now();
        await prefs.setString(_keyLastReset, lastReset.toIso8601String());
      }

      final today = DateTime.now();
      final now = DateTime(today.year, today.month, today.day);
      final lastResetDay = DateTime(lastReset.year, lastReset.month, lastReset.day);

      UsageModel usage;
      if (now.isAfter(lastResetDay)) {
        usage = UsageModel(
          aiTextUsedToday: 0,
          aiPhotoUsedToday: 0,
          isPremium: prefs.getBool(_keyIsPremium) ?? false,
          lastResetDate: now,
        );
        await prefs.setInt(_keyAiText, 0);
        await prefs.setInt(_keyAiPhoto, 0);
        await prefs.setString(_keyLastReset, now.toIso8601String());
      } else {
        usage = UsageModel(
          aiTextUsedToday: prefs.getInt(_keyAiText) ?? 0,
          aiPhotoUsedToday: prefs.getInt(_keyAiPhoto) ?? 0,
          isPremium: prefs.getBool(_keyIsPremium) ?? false,
          lastResetDate: lastReset,
        );
      }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAiText, updated.aiTextUsedToday);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAiPhoto, updated.aiPhotoUsedToday);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsPremium, true);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsPremium, false);
      emit(UsageLoaded(usage: updated));
    }
  }
}
