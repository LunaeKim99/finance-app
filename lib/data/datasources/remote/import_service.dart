import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';

enum ImportFormat { csv, excel }

class ImportResult {
  final List<TransactionModel> transactions;
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final ImportFormat format;

  const ImportResult({
    required this.transactions,
    required this.successCount,
    required this.failedCount,
    required this.errors,
    required this.format,
  });
}

class ImportService {
  static ImportService? _instance;
  factory ImportService() {
    _instance ??= ImportService._internal();
    return _instance!;
  }
  ImportService._internal();

  Future<ImportResult> parseFile(String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'csv':
        return await _parseCsv(filePath);
      case 'xlsx':
      case 'xls':
        return await _parseExcel(filePath);
      default:
        throw Exception('Format file tidak didukung. Gunakan CSV atau Excel (.xlsx)');
    }
  }

  Future<ImportResult> _parseCsv(String filePath) async {
    final List<TransactionModel> transactions = [];
    final List<String> errors = [];
    int failedCount = 0;

    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content, eol: '\n');

      if (rows.isEmpty) {
        throw Exception('File CSV kosong');
      }

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length < 4) {
            errors.add('Baris ${i + 1}: kolom tidak lengkap, dilewati');
            failedCount++;
            continue;
          }

          final transaction = _rowToTransaction(row, i + 1);
          if (transaction != null) {
            transactions.add(transaction);
          } else {
            failedCount++;
          }
        } catch (e) {
          errors.add('Baris ${i + 1}: ${e.toString()}');
          failedCount++;
        }
      }
    } catch (e) {
      throw Exception('Gagal membaca file CSV: ${e.toString()}');
    }

    return ImportResult(
      transactions: transactions,
      successCount: transactions.length,
      failedCount: failedCount,
      errors: errors,
      format: ImportFormat.csv,
    );
  }

  Future<ImportResult> _parseExcel(String filePath) async {
    final List<TransactionModel> transactions = [];
    final List<String> errors = [];
    int failedCount = 0;

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        throw Exception('File Excel kosong');
      }

      for (int i = 1; i < sheet.rows.length; i++) {
        try {
          final row = sheet.rows[i].map((cell) => cell?.value).toList();
          if (row.length < 4) {
            errors.add('Baris ${i + 1}: kolom tidak lengkap, dilewati');
            failedCount++;
            continue;
          }

          final transaction = _rowToTransaction(row, i + 1);
          if (transaction != null) {
            transactions.add(transaction);
          } else {
            failedCount++;
          }
        } catch (e) {
          errors.add('Baris ${i + 1}: ${e.toString()}');
          failedCount++;
        }
      }
    } catch (e) {
      throw Exception('Gagal membaca file Excel: ${e.toString()}');
    }

    return ImportResult(
      transactions: transactions,
      successCount: transactions.length,
      failedCount: failedCount,
      errors: errors,
      format: ImportFormat.excel,
    );
  }

  TransactionModel? _rowToTransaction(List<dynamic> row, int rowNumber) {
    try {
      final dateStr = row[0].toString().trim();
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          date = DateTime.now();
        }
      }

      final typeStr = row[1].toString().trim().toLowerCase();
      final isExpense = typeStr == 'pengeluaran' || typeStr == 'expense' || typeStr == 'keluar';
      final type = isExpense ? TransactionType.expense : TransactionType.income;

      final categoryName = row[2].toString().trim();
      final category = categoryName.isEmpty ? 'Lainnya' : categoryName;

      final nominalStr = row[3].toString().trim().replaceAll('.', '').replaceAll(',', '').replaceAll('Rp', '').replaceAll(' ', '');
      final amount = double.tryParse(nominalStr) ?? 0;

      final note = row.length > 4 ? row[4].toString().trim() : '';

      final id = DateTime.now().millisecondsSinceEpoch.toString() + rowNumber.toString();
      return TransactionModel(
        id: id,
        title: category,
        amount: amount,
        type: type,
        categoryId: category,
        date: date,
        note: note,
        currency: 'IDR',
      );
    } catch (e) {
      debugPrint('Error parse row $rowNumber: $e');
      return null;
    }
  }

  String generateCsvTemplate() {
    const header = 'Tanggal,Tipe,Kategori,Nominal,Catatan';
    const example1 = '2026-04-25,pengeluaran,Makanan,25000,Makan siang';
    const example2 = '2026-04-25,pemasukan,Gaji,5000000,Gaji bulan April';
    const example3 = '2026-04-24,pengeluaran,Transportasi,15000,Grab ke kantor';
    return '$header\n$example1\n$example2\n$example3';
  }
}
