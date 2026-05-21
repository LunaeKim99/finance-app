import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/datasources/pb_helper.dart';
import '../../../../data/datasources/local/sqlite_helper.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  late final TransactionRepositoryImpl _repository;
  late final SmartDbHelper _dbHelper;
  bool _initialized = false;
  StreamSubscription<bool>? _connectivitySub;

  TransactionBloc() : super(const TransactionInitial()) {
    _dbHelper = SmartDbHelper(remote: PbHelper(), local: SqliteHelper());
    _repository = TransactionRepositoryImpl(_dbHelper);
    on<TransactionLoadRequested>(_onLoadTransactions);
    on<TransactionAddRequested>(_onAddTransaction);
    on<TransactionUpdateRequested>(_onUpdateTransaction);
    on<TransactionDeleteRequested>(_onDeleteTransaction);
    on<TransactionMarkSynced>(_onMarkSynced);
  }

  bool get isOnline => _dbHelper.isRemoteAvailable;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    add(const TransactionLoadRequested());
    _connectivitySub = _dbHelper.connectivityStream.listen((_) {
      if (isClosed) return;
      Future.microtask(() {
        if (isClosed) return;
        if (state is TransactionLoaded) {
          add(const TransactionLoadRequested());
        }
      });
    });
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }

  Future<void> _onLoadTransactions(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(
        transactions: transactions,
        isOnline: _dbHelper.isRemoteAvailable,
      ));
    } catch (e) {
      debugPrint('[TransactionBloc] Load error: $e');
      emit(TransactionError(message: 'Gagal memuat transaksi'));
    }
  }

  Future<void> _onAddTransaction(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.addTransaction(event.transaction);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Add error: $e');
      emit(TransactionError(message: 'Gagal menambah transaksi'));
    }
  }

  Future<void> _onUpdateTransaction(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.updateTransaction(event.transaction);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Update error: $e');
      emit(TransactionError(message: 'Gagal mengupdate transaksi'));
    }
  }

  Future<void> _onDeleteTransaction(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.deleteTransaction(event.id);
      add(const TransactionLoadRequested());
    } catch (e) {
      debugPrint('[TransactionBloc] Delete error: $e');
      emit(TransactionError(message: 'Gagal menghapus transaksi'));
    }
  }

  void _onMarkSynced(
    TransactionMarkSynced event,
    Emitter<TransactionState> emit,
  ) {
    final current = state;
    if (current is TransactionLoaded) {
      final updated = current.transactions.map((t) {
        if (t.id == event.id) return t.copyWith(isSynced: true);
        return t;
      }).toList();
      emit(TransactionLoaded(transactions: updated, isOnline: current.isOnline));
    }
  }
}
