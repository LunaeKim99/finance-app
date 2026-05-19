import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_event.dart';
import '../../blocs/category/category_state.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../../blocs/usage/usage_event.dart';
import 'bloc/transaction_bloc.dart';
import 'bloc/transaction_event.dart';
import '../../../data/datasources/remote/receipt_scan_service.dart';
import '../receipt/receipt_review_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  TransactionType _transactionType = TransactionType.expense;
  String _selectedCategory = 'Makanan';
  String _selectedCurrency = 'IDR';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _expenseCatNames = ['Makanan', 'Transportasi', 'Belanja', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Tagihan', 'Lainnya'];
  List<String> _incomeCatNames = ['Gaji', 'Bonus', 'Usaha', 'Investasi', 'Hadiah', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    context.read<CategoryBloc>().add(const CategoryLoadRequested());
    _syncCategoriesFromBloc();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(0);
      _noteController.text = existing.note;
      _transactionType = existing.type;
      _selectedCategory = existing.category;
      _selectedCurrency = existing.currency;
      _selectedDate = existing.date;
    }
  }

  bool get _isEditMode => widget.existingTransaction != null;
  String get _screenTitle => _isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  List<String> get _currentCategories =>
      _transactionType == TransactionType.expense ? _expenseCatNames : _incomeCatNames;

  void _syncCategoriesFromBloc() {
    final state = context.read<CategoryBloc>().state;
    if (state is CategoryLoaded) {
      _expenseCatNames = state.expenseCategories.map((c) => c.name).toList();
      _incomeCatNames = state.incomeCategories.map((c) => c.name).toList();
      if (!_expenseCatNames.contains(_selectedCategory) && !_incomeCatNames.contains(_selectedCategory)) {
        _selectedCategory = _currentCategories.isNotEmpty ? _currentCategories.first : 'Lainnya';
      }
    }
  }

  String _formatNumberWithDot(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return '';
    final number = int.tryParse(cleanText) ?? 0;
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.');
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

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return _buildIOS();
    }

    return _buildAndroid();
  }

  Widget _buildAndroid() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        actions: _isEditMode
            ? [
                IconButton(
                  onPressed: _deleteTransaction,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ]
            : null,
      ),
      body: _buildForm(),
    );
  }

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_screenTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ),
      child: SafeArea(child: _buildForm()),
    );
  }

  Widget _buildForm() {
    final isExpense = _transactionType == TransactionType.expense;
    final accentColor = isExpense ? Colors.red : const Color(0xFF4CAF50);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTopSection(accentColor, isExpense),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                const SizedBox(height: 8),
                _buildCategoryRow(accentColor),
                _buildDivider(),
                _buildDateRow(accentColor),
                _buildDivider(),
                _buildCurrencyRow(),
                _buildDivider(),
                _buildNoteRow(),
                const SizedBox(height: 24),
                _buildScanReceiptButton(),
                const SizedBox(height: 16),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(Color accentColor, bool isExpense) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          _buildTypeSelector(),
          const SizedBox(height: 28),
          Text(
            isExpense ? 'Pengeluaran' : 'Pemasukan',
            style: TextStyle(
              fontSize: 13,
              color: accentColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(_amountFocusNode),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  AppCurrencies.symbolFor(_selectedCurrency),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: accentColor.withValues(alpha: 0.6),
                  ),
                ),
                IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    onChanged: _onAmountChanged,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nominal tidak boleh kosong';
                      }
                      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                      if (double.tryParse(cleanValue) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isExpense = _transactionType == TransactionType.expense;
    final isIOS = Platform.isIOS;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _buildTypeOption(
            label: 'Pengeluaran',
            isSelected: isExpense,
            selectedColor: Colors.red,
            icon: isIOS ? CupertinoIcons.arrow_up_circle_fill : Icons.arrow_upward_rounded,
            onTap: () => setState(() {
              _transactionType = TransactionType.expense;
              _syncCategoriesFromBloc();
              _selectedCategory = _expenseCatNames.isNotEmpty ? _expenseCatNames.first : 'Lainnya';
            }),
          ),
          _buildTypeOption(
            label: 'Pemasukan',
            isSelected: !isExpense,
            selectedColor: const Color(0xFF4CAF50),
            icon: isIOS ? CupertinoIcons.arrow_down_circle_fill : Icons.arrow_downward_rounded,
            onTap: () => setState(() {
              _transactionType = TransactionType.income;
              _syncCategoriesFromBloc();
              _selectedCategory = _incomeCatNames.isNotEmpty ? _incomeCatNames.first : 'Lainnya';
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedColor : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? selectedColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(Color accentColor) {
    final isIOS = Platform.isIOS;

    return InkWell(
      onTap: isIOS ? _showCategoryPickerIOS : _showCategoryPickerAndroid,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(_selectedCategory),
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCategory,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPickerAndroid() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ..._currentCategories.map((category) {
                final isSelected = category == _selectedCategory;
                return ListTile(
                  leading: Icon(
                    _getCategoryIcon(category),
                    color: isSelected
                        ? (_transactionType == TransactionType.expense
                            ? Colors.red
                            : const Color(0xFF4CAF50))
                        : Colors.grey,
                  ),
                  title: Text(
                    category,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? (_transactionType == TransactionType.expense
                              ? Colors.red
                              : const Color(0xFF4CAF50))
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
color: _transactionType == TransactionType.expense
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPickerIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Pilih'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedCategory = _currentCategories[index];
                  });
                },
                children: _currentCategories.map((category) {
                  return Center(child: Text(category));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(Color accentColor) {
    final isIOS = Platform.isIOS;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);

    return InkWell(
      onTap: isIOS
          ? _showDatePickerIOS
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: accentColor),
                  ),
                  child: child!,
                ),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIOS ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyRow() {
    final isIOS = Platform.isIOS;
    final currencyInfo = AppCurrencies.getById(_selectedCurrency);

    return InkWell(
      onTap: isIOS ? _showCurrencyPickerIOS : _showCurrencyPickerAndroid,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                size: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mata Uang',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currencyInfo.symbol} ${currencyInfo.code} - ${currencyInfo.name}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPickerAndroid() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pilih Mata Uang',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppCurrencies.supported.map((currency) {
                    final isSelected = currency.code == _selectedCurrency;
                    return ListTile(
                      leading: Text(
                        currency.symbol,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        '${currency.code} - ${currency.name}',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        setState(() => _selectedCurrency = currency.code);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyPickerIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Pilih'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedCurrency = AppCurrencies.supported[index].code;
                  });
                },
                children: AppCurrencies.supported.map((currency) {
                  return Center(
                    child: Text('${currency.symbol} ${currency.code} - ${currency.name}'),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Platform.isIOS
                  ? CupertinoIcons.pencil
                  : Icons.edit_note_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: _noteController,
              maxLines: null,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Tambah catatan...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(top: 10),
                labelText: 'Catatan',
                labelStyle: TextStyle(fontSize: 11, color: Colors.grey),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.withValues(alpha: 0.2),
      indent: 52,
    );
  }

  void _showDatePickerIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Pilih'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanReceiptButton() {
    final isIOS = Platform.isIOS;

    return OutlinedButton.icon(
      onPressed: _scanReceipt,
      icon: Icon(
        isIOS ? CupertinoIcons.camera : Icons.document_scanner_outlined,
        size: 18,
      ),
      label: const Text('Scan Struk / Nota'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4CAF50),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final usageState = context.read<UsageBloc>().state;
    if (!(usageState is UsageLoaded && usageState.canUseAiPhoto())) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Batas Tercapai'),
            content: const Text(
              'Batas scan struk harian tercapai (2/2). Coba lagi besok atau upgrade ke Premium.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Batas scan struk harian tercapai (2/2). Coba lagi besok atau upgrade ke Premium.',
            ),
          ),
        );
      }
      return;
    }

    final scanner = ReceiptScanService();
    final image = await scanner.pickImage();
    if (image == null) return;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => const CupertinoAlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(width: 12),
              Text('Memproses struk...'),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memproses struk...')),
      );
    }

    try {
      final result = await scanner.scanReceipt(image);
      context.read<UsageBloc>().add(const UsageIncrementAiPhoto());

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptReviewScreen(scanResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal scan: $e')),
        );
      }
    }
  }

  Widget _buildSubmitButton() {
    final isExpense = _transactionType == TransactionType.expense;
    final accentColor = isExpense ? Colors.red : const Color(0xFF4CAF50);
    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final isValid = cleanAmount.isNotEmpty && (double.tryParse(cleanAmount) ?? 0) > 0;

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading || !isValid ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? accentColor : Colors.grey.shade300,
          foregroundColor: isValid ? Colors.white : Colors.grey,
          minimumSize: const Size(double.infinity, 54),
          elevation: isValid ? 2 : 0,
          shadowColor: accentColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditMode ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<TransactionBloc>().add(
        TransactionDeleteRequested(id: widget.existingTransaction!.id!),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      if (Platform.isIOS) {
        _showAlertIOS('Error', 'Nominal tidak boleh kosong');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal tidak boleh kosong')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0;
    final transaction = TransactionModel(
      id: _isEditMode ? widget.existingTransaction?.id : null,
      title: _selectedCategory,
      amount: amount,
      type: _transactionType,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text,
      currency: _selectedCurrency,
      exchangeRateToIdr: AppCurrencies.defaultRates[_selectedCurrency] ?? 1.0,
    );

    if (_isEditMode) {
      context.read<TransactionBloc>().add(TransactionUpdateRequested(transaction: transaction));
    } else {
      context.read<TransactionBloc>().add(TransactionAddRequested(transaction: transaction));
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (Platform.isIOS) {
        _showAlertIOS(
          'Berhasil',
          _isEditMode ? 'Transaksi berhasil diperbarui' : 'Transaksi berhasil ditambahkan',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Transaksi berhasil diperbarui'
                : 'Transaksi berhasil ditambahkan'),
          ),
        );
      }
      Navigator.pop(context);
    }
  }

  void _showAlertIOS(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan':
        return Platform.isIOS ? CupertinoIcons.bag_fill : Icons.restaurant;
      case 'Transportasi':
        return Platform.isIOS ? CupertinoIcons.car_fill : Icons.directions_car;
      case 'Belanja':
        return Platform.isIOS ? CupertinoIcons.bag : Icons.shopping_bag;
      case 'Hiburan':
        return Platform.isIOS ? CupertinoIcons.game_controller_solid : Icons.movie;
      case 'Kesehatan':
        return Platform.isIOS ? CupertinoIcons.heart_fill : Icons.local_hospital;
      case 'Pendidikan':
        return Platform.isIOS ? CupertinoIcons.book_fill : Icons.school;
      case 'Tagihan':
        return Platform.isIOS ? CupertinoIcons.doc_text_fill : Icons.receipt;
      case 'Gaji':
        return Platform.isIOS ? CupertinoIcons.money_dollar : Icons.work;
      case 'Bonus':
        return Platform.isIOS ? CupertinoIcons.gift_fill : Icons.card_giftcard;
      case 'Usaha':
        return Platform.isIOS ? CupertinoIcons.briefcase_fill : Icons.business;
      case 'Investasi':
        return Platform.isIOS ? CupertinoIcons.chart_bar_fill : Icons.trending_up;
      case 'Hadiah':
        return Platform.isIOS ? CupertinoIcons.gift : Icons.card_giftcard;
      default:
        return Platform.isIOS ? CupertinoIcons.ellipsis : Icons.more_horiz;
    }
  }
}
