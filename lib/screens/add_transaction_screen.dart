import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

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
    'investasi',
    'Hadiah',
    'Lainnya',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories =>
      _transactionType == 'expense' ? _expenseCategories : _incomeCategories;

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
        title: const Text('Tambah Transaksi'),
        centerTitle: true,
      ),
      body: _buildForm(),
    );
  }

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tambah Transaksi'),
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
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoSlidingSegmentedControl<String>(
        groupValue: _transactionType,
        children: const {
          'expense': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Pengeluaran'),
          ),
          'income': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Pemasukan'),
          ),
        },
        onValueChanged: (value) {
          setState(() {
            _transactionType = value!;
            _selectedCategory = _currentCategories.first;
          });
        },
      );
    }

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
        ButtonSegment(value: 'income', label: Text('Pemasukan')),
      ],
      selected: {_transactionType},
      onSelectionChanged: (selection) {
        setState(() {
          _transactionType = selection.first;
          _selectedCategory = _currentCategories.first;
        });
      },
    );
  }

  Widget _buildAmountField() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoTextField(
        controller: _amountController,
        placeholder: 'Nominal',
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text('Rp '),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        padding: const EdgeInsets.all(16),
      );
    }

    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Nominal',
        prefixText: 'Rp ',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nominal tidak boleh kosong';
        }
        if (double.tryParse(value) == null) {
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
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCategoryPickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedCategory),
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
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      items: _currentCategories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
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

    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanggal',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDatePickerIOS(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                  const Icon(CupertinoIcons.calendar, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Tanggal'),
      subtitle: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      ),
      trailing: const Icon(Icons.calendar_today),
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
      );
    }

    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Catatan (opsional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoButton.filled(
        onPressed: _isLoading ? null : _saveTransaction,
        child: _isLoading
            ? const CupertinoActivityIndicator()
            : const Text('Simpan'),
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _saveTransaction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : const Text('Simpan'),
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

    final amount = double.tryParse(_amountController.text) ?? 0;
    final transaction = TransactionModel(
      title: _selectedCategory,
      amount: amount,
      type: _transactionType,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text,
    );

    final provider = context.read<TransactionProvider>();
    final success = await provider.addTransaction(transaction);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
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
}