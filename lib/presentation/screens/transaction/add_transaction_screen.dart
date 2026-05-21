import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/constants/default_categories.dart';
import '../../../core/constants/icon_registry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/transaction.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../../blocs/usage/usage_event.dart';
import '../../widgets/glass_card.dart';
import 'bloc/transaction_bloc.dart';
import 'bloc/transaction_event.dart';
import '../../../data/datasources/remote/receipt_scan_service.dart';
import '../receipt/receipt_review_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  TransactionType _transactionType = TransactionType.expense;
  String? _selectedCategoryName;
  String _selectedCurrency = 'IDR';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<String> get _expenseCategoryNames =>
      DefaultCategories.list.where((c) => c.type == 'expense').map((c) => c.name).toList();
  List<String> get _incomeCategoryNames =>
      DefaultCategories.list.where((c) => c.type == 'income').map((c) => c.name).toList();
  List<String> get _currentCategoryNames =>
      _transactionType == TransactionType.expense ? _expenseCategoryNames : _incomeCategoryNames;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    if (_selectedCategoryName == null && _currentCategoryNames.isNotEmpty) {
      _selectedCategoryName = _currentCategoryNames.first;
    }
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(0);
      _noteController.text = existing.note ?? '';
      _transactionType = existing.type;
      _selectedCategoryName = existing.category;
      _selectedCurrency = existing.currency;
      _selectedDate = existing.date;
    }
  }

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _formatNumberWithDot(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return '';
    final number = int.tryParse(cleanText) ?? 0;
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _onAmountChanged(String value) {
    final formatted = _formatNumberWithDot(value);
    if (value != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String get _selectedCurrencyDisplay {
    final match = AppCurrencies.supported.firstWhere(
      (c) => c.code == _selectedCurrency,
      orElse: () => AppCurrencies.supported.first,
    );
    return '${match.symbol} ${match.code} - ${match.name}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _submit() {
    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (rawAmount.isEmpty || int.parse(rawAmount) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah transaksi'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_selectedCategoryName == null) return;

    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _selectedCategoryName!,
      type: _transactionType,
      amount: double.parse(rawAmount),
      category: _selectedCategoryName!,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      currency: _selectedCurrency,
    );

    context.read<TransactionBloc>().add(
      _isEditMode
          ? TransactionUpdateRequested(transaction: transaction)
          : TransactionAddRequested(transaction: transaction),
    );

    Navigator.pop(context);
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah kamu yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionBloc>().add(TransactionDeleteRequested(id: widget.existingTransaction!.safeId));
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final usageState = context.read<UsageBloc>().state;
    if (usageState is UsageLoaded && usageState.remainingAiPhoto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuota scan habis. Upgrade ke Premium untuk kuota tak terbatas.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageFile = await ReceiptScanService().pickImage(fromCamera: false);
      if (imageFile == null) { setState(() => _isLoading = false); return; }
      final scanResult = await ReceiptScanService().scanReceipt(imageFile);
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ReceiptReviewScreen(scanResult: scanResult)),
        );
        if (result == true && mounted) {
          context.read<UsageBloc>().add(const UsageIncrementAiPhoto());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal scan: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == TransactionType.expense;
    final accentColor = isExpense ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTopSection(accentColor, isExpense),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildCategoryField(),
                            const SizedBox(height: AppSpacing.stackSm),
                            _buildDateField(),
                            const SizedBox(height: AppSpacing.stackSm),
                            _buildCurrencyField(),
                            const SizedBox(height: AppSpacing.stackSm),
                            _buildNotesField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
            Text('Tambah Transaksi', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const Spacer(),
            if (_isEditMode)
              IconButton(
                onPressed: _deleteTransaction,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(Color accentColor, bool isExpense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          _buildTypeToggle(isExpense),
          const SizedBox(height: 24),
          Text(
            isExpense ? 'Pengeluaran' : 'Pemasukan',
            style: AppTypography.bodySm.copyWith(color: accentColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Rp', style: AppTypography.headlineMd.copyWith(color: accentColor.withValues(alpha: 0.7))),
              const SizedBox(width: 4),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  onChanged: _onAmountChanged,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTypography.currencyDisplay.copyWith(color: accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(bool isExpense) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _transactionType = TransactionType.expense;
                if (_selectedCategoryName != null && !_currentCategoryNames.contains(_selectedCategoryName)) {
                  _selectedCategoryName = _currentCategoryNames.isNotEmpty ? _currentCategoryNames.first : null;
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isExpense ? AppColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: AppRadius.fullRadius,
                  boxShadow: isExpense
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 16, color: isExpense ? AppColors.secondary : AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Pengeluaran', style: AppTypography.bodySm.copyWith(
                      fontWeight: isExpense ? FontWeight.w600 : FontWeight.w500,
                      color: isExpense ? AppColors.secondary : AppColors.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _transactionType = TransactionType.income;
                if (_selectedCategoryName != null && !_currentCategoryNames.contains(_selectedCategoryName)) {
                  _selectedCategoryName = _currentCategoryNames.isNotEmpty ? _currentCategoryNames.first : null;
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isExpense ? AppColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: AppRadius.fullRadius,
                  boxShadow: !isExpense
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 16, color: !isExpense ? AppColors.primary : AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Pemasukan', style: AppTypography.bodySm.copyWith(
                      fontWeight: !isExpense ? FontWeight.w600 : FontWeight.w500,
                      color: !isExpense ? AppColors.primary : AppColors.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? iconBgColor,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconBgColor ?? AppColors.surfaceContainer,
              borderRadius: AppRadius.fullRadius,
            ),
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return _buildFormField(
      icon: iconDataForCategory(_selectedCategoryName ?? ''),
      label: 'Kategori',
      value: _selectedCategoryName ?? 'Lainnya',
      onTap: _showCategoryPicker,
      iconBgColor: AppColors.surfaceContainer,
    );
  }

  Widget _buildDateField() {
    return _buildFormField(
      icon: Icons.calendar_today_rounded,
      label: 'Tanggal',
      value: _formatDate(_selectedDate),
      onTap: _pickDate,
      iconBgColor: AppColors.primaryFixedDim.withValues(alpha: 0.2),
    );
  }

  Widget _buildCurrencyField() {
    return _buildFormField(
      icon: Icons.attach_money_rounded,
      label: 'Mata Uang',
      value: _selectedCurrencyDisplay,
      onTap: _showCurrencyPicker,
      iconBgColor: AppColors.primaryContainer.withValues(alpha: 0.2),
    );
  }

  Widget _buildNotesField() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppRadius.fullRadius,
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catatan', style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Tambah catatan...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 3,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isEmpty = _amountController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _scanReceipt,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.receipt_long_rounded, size: 20),
              label: Text(_isLoading ? 'Memproses...' : 'Scan Struk / Nota'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEmpty ? null : _submit,
              child: Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan Transaksi'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Kategori', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 16),
            ..._currentCategoryNames.map((cat) => ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(iconDataForCategory(cat), color: AppColors.onSurfaceVariant, size: 20),
              ),
              title: Text(cat, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
              trailing: cat == _selectedCategoryName
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () { setState(() => _selectedCategoryName = cat); Navigator.pop(ctx); },
            )),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Mata Uang', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 16),
            ...AppCurrencies.supported.map((c) => ListTile(
              title: Text('${c.symbol} ${c.code} - ${c.name}', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
              trailing: c.code == _selectedCurrency
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () { setState(() => _selectedCurrency = c.code); Navigator.pop(ctx); },
            )),
          ],
        ),
      ),
    );
  }

  static IconData iconDataForCategory(String category) {
    return CategoryIconRegistry.resolve(category, category);
  }
}
