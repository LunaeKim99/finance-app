import 'package:equatable/equatable.dart';

abstract class UpgradeEvent extends Equatable {
  const UpgradeEvent();

  @override
  List<Object?> get props => [];
}

class UpgradeProcessPayment extends UpgradeEvent {
  final int amount;

  const UpgradeProcessPayment({required this.amount});

  @override
  List<Object?> get props => [amount];
}

class UpgradeSelectPlan extends UpgradeEvent {
  final String plan;

  const UpgradeSelectPlan({required this.plan});

  @override
  List<Object?> get props => [plan];
}
