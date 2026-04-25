import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/usage_provider.dart';
import '../services/receipt_scan_service.dart';
import '../screens/receipt_review_screen.dart';
import '../utils/app_theme.dart';

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

  String _transactionType = 'expense';
  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Tagihan',
    'Lainnya',
  ];

  final List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Usaha',
    'Investasi',
    'Hadiah',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(0);
      _noteController.text = existing.note;
      _transactionType = existing.type;
      _selectedCategory = existing.category;
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
    super.dispose();
  }

  List<String> get _currentCategories =>
      _transactionType == 'expense' ? _expenseCategories : _incomeCategories;

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
      appBar: AppBar(
        title: Text(_screenTitle),
        centerTitle: true,
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildAmountField(),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildNoteField(),
          const SizedBox(height: 16),
          _buildScanReceiptButton(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isIOS = Platform.isIOS;
    final isExpense = _transactionType == 'expense';
    final isIncome = _transactionType == 'income';

    if (isIOS) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _transactionType = 'expense';
                  _selectedCategory = _expenseCategories.first;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isExpense ? const Color(0xFF4CAF50) : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isExpense)
                        const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 16),
                      if (isExpense) const SizedBox(width: 4),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          color: isExpense ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _transactionType = 'income';
                  _selectedCategory = _incomeCategories.first;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isIncome ? const Color(0xFF4CAF50) : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isIncome)
                        const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 16),
                      if (isIncome) const SizedBox(width: 4),
                      Text(
                        'Pemasukan',
                        style: TextStyle(
                          color: isIncome ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _transactionType = 'expense';
                _selectedCategory = _expenseCategories.first;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isExpense ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isExpense)
                      const Icon(Icons.check, color: Colors.white, size: 16),
                    if (isExpense) const SizedBox(width: 4),
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        color: isExpense ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _transactionType = 'income';
                _selectedCategory = _incomeCategories.first;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isIncome ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isIncome)
                      const Icon(Icons.check, color: Colors.white, size: 16),
                    if (isIncome) const SizedBox(width: 4),
                    Text(
                      'Pemasukan',
                      style: TextStyle(
                        color: isIncome ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoTextField(
        controller: _amountController,
        placeholder: '0',
        onChanged: _onAmountChanged,
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text('Rp ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return TextFormField(
      controller: _amountController,
      onChanged: _onAmountChanged,
      decoration: InputDecoration(
        labelText: 'Nominal',
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
        hintText: '0',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }

  Widget _buildCategoryDropdown() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori',
            style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCategoryPickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(_selectedCategory),
                    size: 20,
                    color: _transactionType == 'expense' ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_selectedCategory),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(
          _getCategoryIcon(_selectedCategory),
          color: _transactionType == 'expense' ? Colors.red : Colors.green,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      items: _currentCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 18,
                color: _transactionType == 'expense' ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
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

  Widget _buildDatePicker() {
    final isIOS = Platform.isIOS;
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanggal',
            style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDatePickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(dateStr)),
                  const Icon(CupertinoIcons.chevron_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Tanggal',
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        },
        child: Text(dateStr),
      ),
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

  Widget _buildNoteField() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoTextField(
        controller: _noteController,
        placeholder: 'Catatan (opsional)',
        maxLines: 3,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: 'Catatan (opsional)',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildScanReceiptButton() {
    final isIOS = Platform.isIOS;
    final usageProvider = context.read<UsageProvider>();

    return isIOS
        ? CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.blue,
            onPressed: () => _scanReceipt(usageProvider),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('Scan Struk'),
              ],
            ),
          )
        : OutlinedButton.icon(
            onPressed: () => _scanReceipt(usageProvider),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Struk'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          );
  }

  Future<void> _scanReceipt(UsageProvider usageProvider) async {
    if (!usageProvider.canUseAiPhoto()) {
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
      await usageProvider.incrementAiPhoto();

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
    final isIOS = Platform.isIOS;
    final isValid = _amountController.text.isNotEmpty;

    if (isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: isValid ? const Color(0xFF4CAF50) : Colors.grey,
        borderRadius: BorderRadius.circular(16),
        onPressed: _isLoading ? null : _saveTransaction,
        child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      );
    }

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid 
            ? AppTheme.primaryGreen 
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: isValid 
            ? Colors.white 
            : Theme.of(context).colorScheme.onSurfaceVariant,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
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
    );

    final provider = context.read<TransactionProvider>();
    bool success;
    if (_isEditMode) {
      success = await provider.updateTransaction(transaction);
    } else {
      success = await provider.addTransaction(transaction);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
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