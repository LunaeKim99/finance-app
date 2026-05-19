import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/budget_model.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/constants/icon_registry.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_state.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_state.dart';
import 'bloc/budget_bloc.dart';
import 'bloc/budget_event.dart';
import 'bloc/budget_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetBloc>().add(BudgetLoadRequested(
        month: _selectedMonth,
        year: _selectedYear,
      ));
    });
  }

  void _reloadBudgets() {
    context.read<BudgetBloc>().add(BudgetLoadRequested(
      month: _selectedMonth,
      year: _selectedYear,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, txState) {
        final categoryTotals = txState is TransactionLoaded
            ? txState.getCategoryTotals(_selectedMonth, _selectedYear)
            : <String, double>{};
        return BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, budgetState) {
            final isLoading = budgetState is BudgetLoading || budgetState is BudgetInitial;
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
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(height: 16),
                        if (budgetState is BudgetLoaded) ...[
                          _buildCategoryBudgetList(currencyFormat, categoryTotals, budgetState),
                          const SizedBox(height: 16),
                          _buildNoBudgetCard(categoryTotals, budgetState),
                        ],
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  void showAddBudgetDialog() {
    _showAddBudgetDialog(context);
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
                _reloadBudgets();
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
                  _reloadBudgets();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetList(NumberFormat currencyFormat, Map<String, double> categoryTotals, BudgetLoaded state) {
    final budgets = state.getBudgetsForMonth(_selectedMonth, _selectedYear);
    
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

  Widget _buildNoBudgetCard(Map<String, double> categoryTotals, BudgetLoaded state) {
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
          final budget = state.getBudgetForCategory(e.key);
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
    String selectedCategory = budget?.category ?? preselectedCategory ?? 'Lainnya';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBottomSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                budget == null ? 'Tambah Budget' : 'Edit Budget',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  final state = context.read<CategoryBloc>().state;
                  List<String> categories = [];
                  if (state is CategoryLoaded) {
                    categories = state.expenseCategories.map((c) => c.name).toList();
                  }
                  if (categories.isEmpty) {
                    categories = ['Makanan', 'Transportasi', 'Belanja', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Tagihan', 'Lainnya'];
                  }

                  showModalBottomSheet(
                    context: ctx,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (catCtx) => SafeArea(
                      child: SingleChildScrollView(
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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...categories.map((category) {
                              final isSelected = category == selectedCategory;
                              return ListTile(
                                leading: Icon(
                                  _getCategoryIcon(category),
                                  color: isSelected ? Colors.red : Colors.grey,
                                ),
                                title: Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.red : null,
                                  ),
                                ),
                                trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                                onTap: () {
                                  setBottomSheetState(() => selectedCategory = category);
                                  Navigator.pop(catCtx);
                                },
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(selectedCategory), size: 24, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(selectedCategory),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Limit Budget',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;

                    if (selectedCategory.isEmpty || amount <= 0) {
                      ErrorHandler.showError(ctx, 'Masukkan kategori dan nominal yang valid');
                      return;
                    }

                    context.read<BudgetBloc>().add(BudgetSetRequested(
                      id: budget?.id,
                      name: '$selectedCategory Budget',
                      category: selectedCategory,
                      amount: amount,
                      month: _selectedMonth,
                      year: _selectedYear,
                    ));

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ErrorHandler.showSuccess(ctx, 'Budget berhasil disimpan');
                    }
                  },
                  child: Text(budget == null ? 'Simpan Budget' : 'Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final state = context.read<CategoryBloc>().state;
    if (state is CategoryLoaded) {
      final cat = state.expenseCategories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => Category(name: 'Lainnya', type: 'expense', icon: 'category'),
      );
      return CategoryIconRegistry.resolve(cat.icon, cat.name);
    }
    return CategoryIconRegistry.resolve(null, categoryName);
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
      context.read<BudgetBloc>().add(BudgetDeleteRequested(id: id));
      ErrorHandler.showSuccess(context, 'Budget berhasil dihapus');
    }
  }
}
