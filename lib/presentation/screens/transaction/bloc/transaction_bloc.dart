import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  late final SmartDbHelper _dbHelper;

  TransactionBloc() : super(const TransactionInitial()) {
    _dbHelper = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());
    on<TransactionLoadRequested>(_onLoadTransactions);
    on<TransactionAddRequested>(_onAddTransaction);
    on<TransactionUpdateRequested>(_onUpdateTransaction);
    on<TransactionDeleteRequested>(_onDeleteTransaction);
  }

  SmartDbHelper get dbHelper => _dbHelper;
  bool get isOnline => _dbHelper.isRemoteAvailable;

  Future<void> initialize() async {
    await _dbHelper.initialize();
    _dbHelper.connectivityStream.listen((_) {
      if (state is TransactionLoaded) {
        add(const TransactionLoadRequested());
      }
    });
  }

  Future<void> _onLoadTransactions(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final transactions = await _dbHelper.fetchAllTransactions();
      emit(TransactionLoaded(
        transactions: transactions,
        isOnline: _dbHelper.isRemoteAvailable,
      ));
    } catch (e) {
      debugPrint('[TransactionBloc] Load error: $e');
      emit(const TransactionError(message: 'Gagal memuat transaksi'));
    }
  }

  Future<void> _onAddTransaction(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _dbHelper.createTransaction(event.transaction);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Add error: $e');
      emit(const TransactionError(message: 'Gagal menambah transaksi'));
    }
  }

  Future<void> _onUpdateTransaction(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _dbHelper.updateTransaction(event.transaction.id ?? '', event.transaction);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Update error: $e');
      emit(const TransactionError(message: 'Gagal mengupdate transaksi'));
    }
  }

  Future<void> _onDeleteTransaction(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _dbHelper.deleteTransaction(event.id);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Delete error: $e');
      emit(const TransactionError(message: 'Gagal menghapus transaksi'));
    }
  }
}
