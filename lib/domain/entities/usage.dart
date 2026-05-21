class Usage {
  final int aiTextUsedToday;
  final int aiPhotoUsedToday;
  final bool isPremium;
  final DateTime lastResetDate;

  const Usage({
    this.aiTextUsedToday = 0,
    this.aiPhotoUsedToday = 0,
    this.isPremium = false,
    required this.lastResetDate,
  });

  bool canUseAiText() => isPremium || aiTextUsedToday < 10;
  bool canUseAiPhoto() => isPremium || aiPhotoUsedToday < 5;
  int get remainingAiText => isPremium ? 999 : 10 - aiTextUsedToday;
  int get remainingAiPhoto => isPremium ? 999 : 5 - aiPhotoUsedToday;

  Usage copyWith({
    int? aiTextUsedToday,
    int? aiPhotoUsedToday,
    bool? isPremium,
    DateTime? lastResetDate,
  }) {
    return Usage(
      aiTextUsedToday: aiTextUsedToday ?? this.aiTextUsedToday,
      aiPhotoUsedToday: aiPhotoUsedToday ?? this.aiPhotoUsedToday,
      isPremium: isPremium ?? this.isPremium,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
