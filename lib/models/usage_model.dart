class UsageModel {
  final int aiTextUsedToday;
  final int aiPhotoUsedToday;
  final bool isPremium;
  final DateTime lastResetDate;

  const UsageModel({
    this.aiTextUsedToday = 0,
    this.aiPhotoUsedToday = 0,
    this.isPremium = false,
    required this.lastResetDate,
  });

  UsageModel copyWith({
    int? aiTextUsedToday,
    int? aiPhotoUsedToday,
    bool? isPremium,
    DateTime? lastResetDate,
  }) {
    return UsageModel(
      aiTextUsedToday: aiTextUsedToday ?? this.aiTextUsedToday,
      aiPhotoUsedToday: aiPhotoUsedToday ?? this.aiPhotoUsedToday,
      isPremium: isPremium ?? this.isPremium,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}