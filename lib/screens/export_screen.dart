import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/usage_provider.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String? _loadingType;

  final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  final List<int> _months = List.generate(12, (i) => i + 1);
  final List<int> _years = List.generate(5, (i) => DateTime.now().year - 2 + i);

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Export Data'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ),
        child: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final isIOS = Platform.isIOS;
    final usageProvider = context.watch<UsageProvider>();
    final isPremium = usageProvider.isPremium;
    final txProvider = context.watch<TransactionProvider>();
    final allTx = txProvider.allTransactions;

    final filteredCount = allTx
        .where((t) => t.date.month == _selectedMonth && t.date.year == _selectedYear)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Periode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (isIOS)
            _buildIOSPicker()
          else
            _buildAndroidPicker(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$filteredCount transaksi ditemukan',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isPremium)
            _buildPremiumGate(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildExportButtons(isPremium, filteredCount),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSPicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showMonthPickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getMonthName(_selectedMonth)),
                  const Icon(CupertinoIcons.chevron_down),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showYearPickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_selectedYear'),
                  const Icon(CupertinoIcons.chevron_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidPicker() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Bulan',
              border: OutlineInputBorder(),
            ),
            items: _months.map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text(_getMonthName(m)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedMonth = value!);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Tahun',
              border: OutlineInputBorder(),
            ),
            items: _years.map((y) {
              return DropdownMenuItem(
                value: y,
                child: Text('$y'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedYear = value!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGate() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.lock, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Fitur Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Export data hanya tersedia untuk pengguna Premium.',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<UsageProvider>().upgradeToPremium();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('Upgrade ke Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButtons(bool isPremium, int count) {
    if (count == 0) {
      return Center(
        child: Text(
          'Tidak ada transaksi pada periode ini',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final isIOS = Platform.isIOS;

    return Column(
      children: [
        const Spacer(),
        isIOS
            ? CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: isPremium ? Colors.red : Colors.grey,
                onPressed: isPremium && _loadingType == null
                    ? () => _exportPdf()
                    : null,
                child: _loadingType == 'pdf'
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text),
                          SizedBox(width: 8),
                          Text('Export PDF'),
                        ],
                      ),
              )
            : ElevatedButton.icon(
                onPressed: isPremium && _loadingType == null
                    ? () => _exportPdf()
                    : null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
        const SizedBox(height: 16),
        isIOS
            ? CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: isPremium ? Colors.green : Colors.grey,
                onPressed: isPremium && _loadingType == null
                    ? () => _exportExcel()
                    : null,
                child: _loadingType == 'excel'
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.table),
                          SizedBox(width: 8),
                          Text('Export Excel'),
                        ],
                      ),
              )
            : ElevatedButton.icon(
                onPressed: isPremium && _loadingType == null
                    ? () => _exportExcel()
                    : null,
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getMonthName(int month) {
    final date = DateTime(2024, month);
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  void _showMonthPickerIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 40,
          onSelectedItemChanged: (index) {
            setState(() => _selectedMonth = index + 1);
          },
          children: _months.map((m) => Center(child: Text(_getMonthName(m)))).toList(),
        ),
      ),
    );
  }

  void _showYearPickerIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 40,
          onSelectedItemChanged: (index) {
            setState(() => _selectedYear = _years[index]);
          },
          children: _years.map((y) => Center(child: Text('$y'))).toList(),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _loadingType = 'pdf');

    try {
      final txProvider = context.read<TransactionProvider>();
      final exportService = ExportService();

      final file = await exportService.exportToPdf(
        transactions: txProvider.allTransactions,
        month: _selectedMonth,
        year: _selectedYear,
      );

      await exportService.sharePdf(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF berhasil di-export!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingType = null);
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _loadingType = 'excel');

    try {
      final txProvider = context.read<TransactionProvider>();
      final exportService = ExportService();

      final file = await exportService.exportToExcel(
        transactions: txProvider.allTransactions,
        month: _selectedMonth,
        year: _selectedYear,
      );

      await exportService.shareExcel(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel berhasil di-export!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export Excel: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingType = null);
      }
    }
  }
}