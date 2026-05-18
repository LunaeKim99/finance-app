import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final double balance;
  final double monthlyIncome;
  final double monthlyExpense;
  final bool isOnline;

  const DashboardLoaded({
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [balance, monthlyIncome, monthlyExpense, isOnline];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
