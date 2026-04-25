import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';

class ExportService {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  Future<File> exportToPdf({
    required List<TransactionModel> transactions,
    required int month,
    required int year,
  }) async {
    final filteredTx = transactions.where((t) =>
        t.date.month == month && t.date.year == year).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in filteredTx) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Keuangan\n${_monthFormat.format(DateTime(year, month))}',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Pemasukan:',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(_currencyFormat.format(totalIncome),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      )),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Pengeluaran:',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(_currencyFormat.format(totalExpense),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      )),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Saldo:',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Text(_currencyFormat.format(totalIncome - totalExpense),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Daftar Transaksi (${filteredTx.length} transaksi)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Keterangan', 'Kategori', 'Pemasukan', 'Pengeluaran'],
            data: filteredTx.map((tx) => [
              _dateFormat.format(tx.date),
              tx.title,
              tx.category,
              tx.type == 'income' ? _currencyFormat.format(tx.amount) : '-',
              tx.type == 'expense' ? _currencyFormat.format(tx.amount) : '-',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/laporan_${month}_$year.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> exportToExcel({
    required List<TransactionModel> transactions,
    required int month,
    required int year,
  }) async {
    final filteredTx = transactions.where((t) =>
        t.date.month == month && t.date.year == year).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final buffer = StringBuffer();
    buffer.writeln('No,Tanggal,Judul,Kategori,Tipe,Nominal,Catatan');

    for (var i = 0; i < filteredTx.length; i++) {
      final tx = filteredTx[i];
      final row = i + 1;
      final tipe = tx.type == 'income' ? 'Pemasukan' : 'Pengeluaran';
      buffer.writeln('$row,${_dateFormat.format(tx.date)},${tx.title},${tx.category},$tipe,${tx.amount},${tx.note}');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/transaksi_${month}_$year.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return file;
  }

  Future<void> sharePdf(File file) async {
    await Printing.sharePdf(bytes: await file.readAsBytes(), filename: file.path);
  }

  Future<void> shareExcel(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}