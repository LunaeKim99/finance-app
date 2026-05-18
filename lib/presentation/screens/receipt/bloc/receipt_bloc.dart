import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'receipt_event.dart';
import 'receipt_state.dart';
import '../data/receipt_datasource.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/transaction_type.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  final ReceiptDatasource _datasource;

  ReceiptBloc({required ReceiptDatasource datasource})
      : _datasource = datasource,
        super(const ReceiptInitial()) {
    on<ReceiptSaveRequested>(_onSave);
  }

  Future<void> _onSave(
    ReceiptSaveRequested event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(const ReceiptSaving());
    try {
      if (event.isSingleTransaction) {
        final total = event.items.fold(0.0, (sum, item) => sum + item.price);
        final transaction = TransactionModel(
          title: event.scanResult.merchant.isNotEmpty
              ? event.scanResult.merchant
              : 'Pembelian',
          amount: total,
          type: TransactionType.expense,
          category: event.items.isNotEmpty ? event.items.first.category : 'Lainnya',
          date: event.scanResult.date ?? DateTime.now(),
          note: 'Dari scan struk',
        );
        await _datasource.createTransaction(transaction);
      } else {
        for (final item in event.items) {
          final transaction = TransactionModel(
            title: item.name,
            amount: item.price,
            type: TransactionType.expense,
            category: item.category,
            date: event.scanResult.date ?? DateTime.now(),
            note: 'Dari scan struk',
          );
          await _datasource.createTransaction(transaction);
        }
      }
      emit(const ReceiptSaved());
    } catch (e) {
      debugPrint('[ReceiptBloc] Save error: $e');
      emit(ReceiptError(message: 'Gagal menyimpan: ${e.toString()}'));
    }
  }
}
