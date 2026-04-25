import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/usage_model.dart';

class UsageProvider extends ChangeNotifier {
  static const String _keyAiText = 'usage_ai_text';
  static const String _keyAiPhoto = 'usage_ai_photo';
  static const String _keyIsPremium = 'usage_is_premium';
  static const String _keyLastReset = 'usage_last_reset';

  UsageModel _usage = UsageModel(
    lastResetDate: DateTime.now(),
  );
  bool _isInitialized = false;

  UsageModel get usage => _usage;
  bool get isPremium => AppConfig.allFeaturesUnlocked ? true : _usage.isPremium;
  bool get isInitialized => _isInitialized;

  int get remainingAiText => AppConfig.allFeaturesUnlocked ? -1 : (_usage.isPremium ? -1 : (10 - _usage.aiTextUsedToday));
  int get remainingAiPhoto => AppConfig.allFeaturesUnlocked ? -1 : (_usage.isPremium ? -1 : (2 - _usage.aiPhotoUsedToday));

  Future<void> initialize() async {
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

    if (now.isAfter(lastResetDay)) {
      _usage = UsageModel(
        aiTextUsedToday: 0,
        aiPhotoUsedToday: 0,
        isPremium: prefs.getBool(_keyIsPremium) ?? false,
        lastResetDate: now,
      );
      await prefs.setInt(_keyAiText, 0);
      await prefs.setInt(_keyAiPhoto, 0);
      await prefs.setString(_keyLastReset, now.toIso8601String());
    } else {
      _usage = UsageModel(
        aiTextUsedToday: prefs.getInt(_keyAiText) ?? 0,
        aiPhotoUsedToday: prefs.getInt(_keyAiPhoto) ?? 0,
        isPremium: prefs.getBool(_keyIsPremium) ?? false,
        lastResetDate: lastReset,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  bool canUseAiText() {
    if (AppConfig.allFeaturesUnlocked) return true;
    return _usage.isPremium || _usage.aiTextUsedToday < 10;
  }

  bool canUseAiPhoto() {
    if (AppConfig.allFeaturesUnlocked) return true;
    return _usage.isPremium || _usage.aiPhotoUsedToday < 2;
  }

  Future<void> incrementAiText() async {
    if (_usage.isPremium) return;

    _usage = _usage.copyWith(aiTextUsedToday: _usage.aiTextUsedToday + 1);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAiText, _usage.aiTextUsedToday);
  }

  Future<void> incrementAiPhoto() async {
    if (_usage.isPremium) return;

    _usage = _usage.copyWith(aiPhotoUsedToday: _usage.aiPhotoUsedToday + 1);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAiPhoto, _usage.aiPhotoUsedToday);
  }

  Future<void> upgradeToPremium() async {
    _usage = _usage.copyWith(isPremium: true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
  }

  Future<void> downgradeToFree() async {
    _usage = _usage.copyWith(isPremium: false);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, false);
  }
}