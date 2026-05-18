import 'package:equatable/equatable.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();

  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();
}

class ReceiptSaving extends ReceiptState {
  const ReceiptSaving();
}

class ReceiptSaved extends ReceiptState {
  const ReceiptSaved();
}

class ReceiptError extends ReceiptState {
  final String message;

  const ReceiptError({required this.message});

  @override
  List<Object?> get props => [message];
}
