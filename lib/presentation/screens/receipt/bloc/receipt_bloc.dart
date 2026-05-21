import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'receipt_event.dart';
import 'receipt_state.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';
import '../../../../domain/entities/transaction.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  final TransactionRepositoryImpl _repository;

  ReceiptBloc()
      : _repository = TransactionRepositoryImpl(
          SmartDbHelper(remote: PbHelper(), local: SqliteHelper()),
        ),
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
        final transaction = Transaction(
          title: event.scanResult.merchant.isNotEmpty
              ? event.scanResult.merchant
              : 'Pembelian',
          amount: total,
          type: TransactionType.expense,
          category: event.items.isNotEmpty ? event.items.first.category : 'Lainnya',
          date: event.scanResult.date ?? DateTime.now(),
          note: 'Dari scan struk',
          currency: 'IDR',
        );
        await _repository.addTransaction(transaction);
      } else {
        for (final item in event.items) {
          final transaction = Transaction(
            title: item.name,
            amount: item.price,
            type: TransactionType.expense,
            category: item.category,
            date: event.scanResult.date ?? DateTime.now(),
            note: 'Dari scan struk',
            currency: 'IDR',
          );
          await _repository.addTransaction(transaction);
        }
      }
      emit(const ReceiptSaved());
    } catch (e) {
      debugPrint('[ReceiptBloc] Save error: $e');
      emit(ReceiptError(message: 'Gagal menyimpan: ${e.toString()}'));
    }
  }
}
