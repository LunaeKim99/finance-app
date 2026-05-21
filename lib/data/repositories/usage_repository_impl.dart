import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/usage.dart';
import '../../domain/repositories/usage_repository.dart';

class UsageRepositoryImpl implements UsageRepository {
  static const String _keyAiText = 'usage_ai_text';
  static const String _keyAiPhoto = 'usage_ai_photo';
  static const String _keyIsPremium = 'usage_is_premium';
  static const String _keyLastReset = 'usage_last_reset';

  @override
  Future<Usage> load() async {
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
      await prefs.setInt(_keyAiText, 0);
      await prefs.setInt(_keyAiPhoto, 0);
      await prefs.setString(_keyLastReset, now.toIso8601String());
      return Usage(
        aiTextUsedToday: 0,
        aiPhotoUsedToday: 0,
        isPremium: prefs.getBool(_keyIsPremium) ?? false,
        lastResetDate: now,
      );
    }

    return Usage(
      aiTextUsedToday: prefs.getInt(_keyAiText) ?? 0,
      aiPhotoUsedToday: prefs.getInt(_keyAiPhoto) ?? 0,
      isPremium: prefs.getBool(_keyIsPremium) ?? false,
      lastResetDate: lastReset,
    );
  }

  @override
  Future<void> save(Usage usage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAiText, usage.aiTextUsedToday);
    await prefs.setInt(_keyAiPhoto, usage.aiPhotoUsedToday);
    await prefs.setBool(_keyIsPremium, usage.isPremium);
    await prefs.setString(_keyLastReset, usage.lastResetDate.toIso8601String());
  }
}
