import 'package:pocketbase/pocketbase.dart';
import '../models/transaction_model.dart';

class PbHelper {
  static PbHelper? _instance;
  late PocketBase _pb;
  bool _isInitialized = false;

  factory PbHelper() {
    _instance ??= PbHelper._internal();
    return _instance!;
  }

  PbHelper._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    const defaultUrl = 'http://127.0.0.1:8090';
    _pb = PocketBase(defaultUrl);
    _isInitialized = true;
  }

  PocketBase get pb => _pb;

  Future<List<TransactionModel>> fetchAll() async {
    try {
      final result = await _pb.collection('transactions').getList(
        sort: '-date',
      );
      return result.items.map((record) => TransactionModel.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data: ${e.toString()}');
    }
  }

  Future<TransactionModel> create(TransactionModel t) async {
    try {
      final result = await _pb.collection('transactions').create(body: t.toJson());
      return TransactionModel.fromRecord(result);
    } catch (e) {
      throw Exception('Gagal membuat transaksi: ${e.toString()}');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _pb.collection('transactions').delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: ${e.toString()}');
    }
  }

  Future<TransactionModel> update(String id, TransactionModel t) async {
    try {
      final result = await _pb.collection('transactions').update(id, body: t.toJson());
      return TransactionModel.fromRecord(result);
    } catch (e) {
      throw Exception('Gagal mengupdate transaksi: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> fetchByMonth(int month, int year) async {
    try {
      final endDate = DateTime(year, month + 1, 0);
      
      final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
      final endStr = '$year-${month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final result = await _pb.collection('transactions').getList(
        filter: 'date >= "$startStr" && date <= "$endStr"',
        sort: '-date',
      );
      return result.items.map((record) => TransactionModel.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data bulan: ${e.toString()}');
    }
  }
}