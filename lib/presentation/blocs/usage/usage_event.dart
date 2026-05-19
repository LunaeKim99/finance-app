import 'package:equatable/equatable.dart';

abstract class UsageEvent extends Equatable {
  const UsageEvent();

  @override
  List<Object?> get props => [];
}

class UsageLoadRequested extends UsageEvent {
  const UsageLoadRequested();
}

class UsageIncrementAiText extends UsageEvent {
  const UsageIncrementAiText();
}

class UsageIncrementAiPhoto extends UsageEvent {
  const UsageIncrementAiPhoto();
}

class UsageUpgradeToPremium extends UsageEvent {
  const UsageUpgradeToPremium();
}

class UsageDowngradeToFree extends UsageEvent {
  const UsageDowngradeToFree();
}
