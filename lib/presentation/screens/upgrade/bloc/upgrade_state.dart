import 'package:equatable/equatable.dart';

abstract class UpgradeState extends Equatable {
  const UpgradeState();

  @override
  List<Object?> get props => [];
}

class UpgradeInitial extends UpgradeState {
  const UpgradeInitial();
}

class UpgradeLoading extends UpgradeState {
  final String? message;

  const UpgradeLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class UpgradeSuccess extends UpgradeState {
  const UpgradeSuccess();
}

class UpgradeError extends UpgradeState {
  final String message;

  const UpgradeError({required this.message});

  @override
  List<Object?> get props => [message];
}
