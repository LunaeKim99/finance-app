import 'package:equatable/equatable.dart';
import '../../../data/models/usage_model.dart';
import '../../../core/config/app_config.dart';

abstract class UsageState extends Equatable {
  const UsageState();

  @override
  List<Object?> get props => [];
}

class UsageInitial extends UsageState {
  const UsageInitial();
}

class UsageLoading extends UsageState {
  const UsageLoading();
}

class UsageLoaded extends UsageState {
  final UsageModel usage;

  const UsageLoaded({required this.usage});

  @override
  List<Object?> get props => [usage];

  bool get isPremium => AppConfig.allFeaturesUnlocked ? true : usage.isPremium;
  int get remainingAiText => AppConfig.allFeaturesUnlocked ? -1 : (usage.isPremium ? -1 : (10 - usage.aiTextUsedToday));
  int get remainingAiPhoto => AppConfig.allFeaturesUnlocked ? -1 : (usage.isPremium ? -1 : (2 - usage.aiPhotoUsedToday));

  bool canUseAiText() {
    if (AppConfig.allFeaturesUnlocked) return true;
    return usage.isPremium || usage.aiTextUsedToday < 10;
  }

  bool canUseAiPhoto() {
    if (AppConfig.allFeaturesUnlocked) return true;
    return usage.isPremium || usage.aiPhotoUsedToday < 2;
  }

  bool canImport() {
    if (AppConfig.allFeaturesUnlocked) return true;
    return usage.isPremium;
  }
}

class UsageError extends UsageState {
  final String message;

  const UsageError({required this.message});

  @override
  List<Object?> get props => [message];
}
