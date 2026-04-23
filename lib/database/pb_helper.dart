import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/transaction_model.dart';

class PbHelper {
  static PbHelper? _instance;
  late PocketBase _pb;
  bool _isInitialized = false;

  static const String defaultUrl = 'http://192.168.18.6:8090';
  static const String emulatorUrl = 'http://10.0.2.2:8090';
  static const String localhostUrl = 'http://127.0.0.1:8090';

  factory PbHelper() {
    _instance ??= PbHelper._internal();
    return _instance!;
  }

  PbHelper._internal();

  String _getBaseUrl() {
    if (kIsWeb) {
      return defaultUrl;
    }

    if (Platform.isAndroid) {
      return emulatorUrl;
    }

    if (Platform.isIOS) {
      if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
        return localhostUrl;
      }
      return defaultUrl;
    }

    return defaultUrl;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _pb = PocketBase(_getBaseUrl());
    _isInitialized = true;
  }

  PocketBase get pb => _pb;

  TransactionModel _recordToModel(RecordModel record) {
    return TransactionModel(
      id: record.id,
      title: record.data['title'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      type: record.data['type'] as String,
      category: record.data['category'] as String,
      date: DateTime.parse(record.data['date'] as String),
      note: (record.data['note'] as String?) ?? '',
    );
  }

  Future<List<TransactionModel>> fetchAll() async {
    try {
      final result = await _pb.collection('transactions').getList(
        sort: '-date',
      );
      return result.items.map((record) => _recordToModel(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data: ${e.toString()}');
    }
  }

  Future<TransactionModel> create(TransactionModel t) async {
    try {
      final result = await _pb.collection('transactions').create(body: t.toJson());
      return _recordToModel(result);
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
      return _recordToModel(result);
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
      return result.items.map((record) => _recordToModel(record)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data bulan: ${e.toString()}');
    }
  }
}