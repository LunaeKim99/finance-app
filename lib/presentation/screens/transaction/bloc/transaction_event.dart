import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionLoadRequested extends TransactionEvent {
  const TransactionLoadRequested();
}

class TransactionAddRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionAddRequested({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionUpdateRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionUpdateRequested({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionDeleteRequested extends TransactionEvent {
  final String id;

  const TransactionDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

class TransactionMarkSynced extends TransactionEvent {
  final String id;

  const TransactionMarkSynced({required this.id});

  @override
  List<Object?> get props => [id];
}
