import 'package:equatable/equatable.dart';
import '../../../../data/models/receipt_scan_result.dart';

abstract class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object?> get props => [];
}

class ReceiptSaveRequested extends ReceiptEvent {
  final ReceiptScanResult scanResult;
  final List<ReceiptItem> items;
  final bool isSingleTransaction;

  const ReceiptSaveRequested({
    required this.scanResult,
    required this.items,
    required this.isSingleTransaction,
  });

  @override
  List<Object?> get props => [scanResult, items, isSingleTransaction];
}
