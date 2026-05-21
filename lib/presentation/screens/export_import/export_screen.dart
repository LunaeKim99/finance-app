import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/datasources/remote/export_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart' as data;
import '../../../domain/entities/transaction.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_state.dart';
import '../upgrade/upgrade_screen.dart';
import 'import_screen.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _loadingType;

  final List<int> _months = List.generate(12, (i) => i + 1);
  final List<int> _years = List.generate(5, (i) => DateTime.now().year - 2 + i);

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Import & Export Data'),
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
        title: const Text('Import & Export Data'),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<UsageBloc, UsageState>(
      builder: (context, usageState) {
        final isPremium = usageState is UsageLoaded ? usageState.isPremium : false;
        return BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, txState) {
            final allTx = txState is TransactionLoaded ? txState.transactions : <Transaction>[];
            final filteredCount = allTx
                .where((t) => t.date.month == _selectedMonth && t.date.year == _selectedYear)
                .length;
            return _buildExportContent(isPremium, filteredCount);
          },
        );
      },
    );
  }

  Widget _buildExportContent(bool isPremium, int filteredCount) {
    final isIOS = Platform.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ImportScreen()),
                    );
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 20),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          _buildExportButtons(isPremium, filteredCount),
          const SizedBox(height: 16),
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
            initialValue: _selectedMonth,
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
            initialValue: _selectedYear,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.08),
            const Color(0xFF4CAF50).withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Export data tersedia untuk pengguna Premium',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Upgrade ke Premium',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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
        const SizedBox(height: 24),
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

  Future<String?> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan',
    );
    return result;
  }

  Future<String?> _showSaveOrShareDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Simpan atau Bagikan?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih cara menyimpan file export kamu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  onTap: () => Navigator.pop(context, 'folder'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  title: const Text(
                    'Simpan ke Folder',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Pilih folder penyimpanan di HP kamu',
                    style: TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 8),
                ListTile(
                  onTap: () => Navigator.pop(context, 'share'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  title: const Text(
                    'Bagikan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Kirim via WhatsApp, Drive, Email, dll',
                    style: TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  List<TransactionModel> _toModelList(List<Transaction> entities) {
    return entities.map((e) => TransactionModel(
      id: e.id,
      title: e.title,
      amount: e.amount,
      type: e.type == TransactionType.income ? data.TransactionType.income : data.TransactionType.expense,
      categoryId: e.category,
      date: e.date,
      note: e.note ?? '',
      isSynced: e.isSynced,
      currency: e.currency,
      exchangeRateToIdr: e.exchangeRateToIdr,
    )).toList();
  }

  Future<void> _exportPdf() async {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      setState(() => _loadingType = 'pdf');
      try {
        final txState = context.read<TransactionBloc>().state;
        if (txState is! TransactionLoaded) return;
        final exportService = ExportService();
        final file = await exportService.exportToPdf(
          transactions: _toModelList(txState.transactions),
          month: _selectedMonth,
          year: _selectedYear,
        );
        await exportService.sharePdf(file);
        if (mounted) _showSnackbar('PDF berhasil di-export!');
      } catch (e) {
        if (mounted) _showSnackbar('Gagal export PDF: $e', isError: true);
      } finally {
        if (mounted) setState(() => _loadingType = null);
      }
      return;
    }

    final choice = await _showSaveOrShareDialog(context);
    if (choice == null) return;

    setState(() => _loadingType = 'pdf');

    try {
      final txState = context.read<TransactionBloc>().state;
      if (txState is! TransactionLoaded) return;
      final exportService = ExportService();
      final file = await exportService.exportToPdf(
        transactions: _toModelList(txState.transactions),
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (choice == 'folder') {
        final folderPath = await _pickFolder();
        if (folderPath == null) {
          if (mounted) setState(() => _loadingType = null);
          return;
        }
        await exportService.savePdfToFolder(file, folderPath);
        if (mounted) _showSnackbar('PDF disimpan ke folder yang dipilih!');
      } else {
        await exportService.sharePdf(file);
        if (mounted) _showSnackbar('PDF berhasil di-export!');
      }
    } catch (e) {
      if (mounted) _showSnackbar('Gagal export PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }

  Future<void> _exportExcel() async {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      setState(() => _loadingType = 'excel');
      try {
        final txState = context.read<TransactionBloc>().state;
        if (txState is! TransactionLoaded) return;
        final exportService = ExportService();
        final file = await exportService.exportToExcel(
          transactions: _toModelList(txState.transactions),
          month: _selectedMonth,
          year: _selectedYear,
        );
        await exportService.shareExcel(file);
        if (mounted) _showSnackbar('Excel berhasil di-export!');
      } catch (e) {
        if (mounted) _showSnackbar('Gagal export Excel: $e', isError: true);
      } finally {
        if (mounted) setState(() => _loadingType = null);
      }
      return;
    }

    final choice = await _showSaveOrShareDialog(context);
    if (choice == null) return;

    setState(() => _loadingType = 'excel');

    try {
      final txState = context.read<TransactionBloc>().state;
      if (txState is! TransactionLoaded) return;
      final exportService = ExportService();
      final file = await exportService.exportToExcel(
        transactions: _toModelList(txState.transactions),
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (choice == 'folder') {
        final folderPath = await _pickFolder();
        if (folderPath == null) {
          if (mounted) setState(() => _loadingType = null);
          return;
        }
        await exportService.saveExcelToFolder(file, folderPath);
        if (mounted) _showSnackbar('Excel disimpan ke folder yang dipilih!');
      } else {
        await exportService.shareExcel(file);
        if (mounted) _showSnackbar('Excel berhasil di-export!');
      }
    } catch (e) {
      if (mounted) _showSnackbar('Gagal export Excel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }
}
