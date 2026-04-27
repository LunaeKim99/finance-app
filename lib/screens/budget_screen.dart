import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/error_handler.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final categoryTotals = txProvider.getCategoryTotals(_selectedMonth, _selectedYear);

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Bulanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 16),
                _buildCategoryBudgetList(currencyFormat, categoryTotals, budgetProvider),
                const SizedBox(height: 16),
                _buildNoBudgetCard(categoryTotals, budgetProvider),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Budget'),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(_selectedYear, _selectedMonth));
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
              },
            ),
            Text(
              monthName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final now = DateTime.now();
                if (_selectedYear < now.year || (_selectedYear == now.year && _selectedMonth < now.month)) {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetList(NumberFormat currencyFormat, Map<String, double> categoryTotals, BudgetProvider provider) {
    final budgets = provider.getBudgetsForMonth(_selectedMonth, _selectedYear);
    
    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget per Kategori', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...budgets.map((budget) {
          final spent = categoryTotals[budget.category] ?? 0;
          final percent = budget.amount > 0 ? (spent / budget.amount) : 0.0;
          final isOver = percent >= 1.0;
          final isWarning = percent >= 0.8 && percent < 1.0;

          Color progressColor;
          if (isOver) {
            progressColor = Colors.red;
          } else if (isWarning) {
            progressColor = Colors.orange;
          } else {
            progressColor = const Color(0xFF4CAF50);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.category,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditBudgetDialog(context, budget),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteBudget(budget.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currencyFormat.format(spent)} / ${currencyFormat.format(budget.amount)}',
                        style: TextStyle(
                          color: isOver ? Colors.red : (isWarning ? Colors.orange : Colors.grey),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isOver ? Colors.red : (isWarning ? Colors.orange : Colors.grey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Over budget ${currencyFormat.format(spent - budget.amount)}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoBudgetCard(Map<String, double> categoryTotals, BudgetProvider provider) {
    if (categoryTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Belum ada transaksi bulan ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('Catat transaksi terlebih dahulu untuk melihat budget'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori Tanpa Budget', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...categoryTotals.entries.where((e) {
          final budget = provider.getBudgetForCategory(e.key, _selectedMonth, _selectedYear);
          return budget == null;
        }).map((entry) {
          final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(entry.key),
              subtitle: Text(currencyFormat.format(entry.value)),
              trailing: TextButton(
                onPressed: () => _showAddBudgetDialog(context, preselectedCategory: entry.key),
                child: const Text('Tambah'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (result != null) {
      setState(() {
        _selectedMonth = result.month;
        _selectedYear = result.year;
      });
    }
  }

  void _showAddBudgetDialog(BuildContext context, {String? preselectedCategory}) {
    _showBudgetDialog(context, null, preselectedCategory: preselectedCategory);
  }

  void _showEditBudgetDialog(BuildContext context, BudgetModel budget) {
    _showBudgetDialog(context, budget);
  }

  void _showBudgetDialog(BuildContext context, BudgetModel? budget, {String? preselectedCategory}) {
    final amountController = TextEditingController(
      text: budget?.amount.toStringAsFixed(0) ?? '',
    );
    final categoryController = TextEditingController(text: budget?.category ?? preselectedCategory ?? '');

    final expenseCategories = [
      'Makanan',
      'Transportasi',
      'Belanja',
      'Hiburan',
      'Kesehatan',
      'Pendidikan',
      'Tagihan',
      'Lainnya',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget == null ? 'Tambah Budget' : 'Edit Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: categoryController.text),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return expenseCategories;
                  }
                  return expenseCategories.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  categoryController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => categoryController.text = value,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Limit Budget',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final category = categoryController.text.trim();
              final amount = double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;

              if (category.isEmpty || amount <= 0) {
                ErrorHandler.showError(context, 'Masukkan kategori dan nominal yang valid');
                return;
              }

              final provider = context.read<BudgetProvider>();
              final success = await provider.setBudget(
                id: budget?.id,
                name: '$category Budget',
                category: category,
                amount: amount,
                month: _selectedMonth,
                year: _selectedYear,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ErrorHandler.showSuccess(context, 'Budget berhasil disimpan');
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Budget'),
        content: const Text('Yakin ingin menghapus budget ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<BudgetProvider>();
      final success = await provider.deleteBudget(id);
      if (success && mounted) {
        ErrorHandler.showSuccess(context, 'Budget berhasil dihapus');
      }
    }
  }
}