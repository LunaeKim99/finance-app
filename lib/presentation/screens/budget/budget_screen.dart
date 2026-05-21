import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/default_categories.dart';
import '../../../domain/entities/budget.dart';
import '../../widgets/budget/budget_progress_card.dart';
import '../../widgets/month_selector.dart';
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
      context.read<BudgetBloc>().add(BudgetLoadRequested(month: _selectedMonth, year: _selectedYear));
    });
  }

  void _reloadBudgets() {
    context.read<BudgetBloc>().add(BudgetLoadRequested(month: _selectedMonth, year: _selectedYear));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, txState) {
        final categoryTotals = txState is TransactionLoaded
            ? txState.getCategoryTotals(_selectedMonth, _selectedYear)
            : <String, double>{};

        return BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, budgetState) {
            final isLoading = budgetState is BudgetLoading || budgetState is BudgetInitial;
            final budgets = budgetState is BudgetLoaded
                ? budgetState.getBudgetsForMonth(_selectedMonth, _selectedYear)
                : <Budget>[];
            final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.amount);

            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildMonthSelector(),
                    if (!isLoading)
                      Expanded(
                        child: budgets.isEmpty
                            ? _buildEmptyState()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                children: [
                                  _buildCategorySectionTitle(totalBudget, currencyFormat),
                                  const SizedBox(height: 8),
                                  ...budgets.map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: BudgetProgressCard(
                                      category: b.category,
                                      budgetAmount: b.amount,
                                      spentAmount: categoryTotals[b.category] ?? 0,
                                      onTap: () => _showEditBudgetDialog(b),
                                    ),
                                  )),
                                  _buildNoBudgetCard(categoryTotals, budgets),
                                ],
                              ),
                      )
                    else
                      const Expanded(child: Center(child: CircularProgressIndicator.adaptive())),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddBudgetDialog(context),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
                child: const Icon(Icons.add_rounded),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.surfaceContainerHighest, width: 0.5)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text('Budget Bulanan', style: AppTypography.headlineSm.copyWith(color: cs.onSurface)),
            const Spacer(),
            IconButton(
              onPressed: _pickMonth,
              icon: Icon(Icons.calendar_month_rounded, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return MonthSelector(
      selectedMonth: DateTime(_selectedYear, _selectedMonth),
      onPrevious: () => setState(() { _prevMonth(); _reloadBudgets(); }),
      onNext: () => setState(() { _nextMonth(); _reloadBudgets(); }),
    );
  }

  Widget _buildCategorySectionTitle(double total, NumberFormat fmt) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('KATEGORI BUDGET', style: AppTypography.labelMono.copyWith(color: cs.onSurfaceVariant)),
          Text('Total: ${fmt.format(total)}', style: AppTypography.bodySm.copyWith(color: cs.primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary.withValues(alpha: 0.08)),
            child: Icon(Icons.account_balance_wallet_rounded, size: 32, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text('Belum ada budget', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Atur budget untuk kelola keuangan', style: AppTypography.bodySm.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddBudgetDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudgetCard(Map<String, double> categoryTotals, List<Budget> budgets) {
    final cs = Theme.of(context).colorScheme;
    final allCategories = DefaultCategories.list
        .where((c) => c.type == 'expense')
        .map((c) => c.name)
        .where((n) => !budgets.any((b) => b.category == n))
        .toList();

    if (allCategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KATEGORI TANPA BUDGET', style: AppTypography.labelMono.copyWith(fontSize: 10, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...allCategories.map((cat) => Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              title: Text(cat, style: AppTypography.bodyMd.copyWith(color: cs.onSurface)),
              trailing: TextButton(
                onPressed: () => _showAddBudgetDialog(context, presetCategory: cat),
                child: const Text('Tambah'),
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _prevMonth() {
    if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; }
    else { _selectedMonth--; }
  }

  void _nextMonth() {
    if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; }
    else { _selectedMonth++; }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() { _selectedMonth = picked.month; _selectedYear = picked.year; });
      _reloadBudgets();
    }
  }

  void _showAddBudgetDialog(BuildContext context, {String? presetCategory}) {
    final amountController = TextEditingController();
    String? selectedCategory = presetCategory;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: Text(presetCategory != null ? 'Tambah Budget' : 'Budget Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (presetCategory == null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  initialValue: selectedCategory,
                  items: _getUnbudgetedCategories().map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => selectedCategory = v,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Jumlah Budget', prefixText: 'Rp '),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final category = presetCategory ?? selectedCategory;
              final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
              if (category == null || amount == null || amount <= 0) return;
              context.read<BudgetBloc>().add(BudgetAddRequested(budget: Budget(
                name: category,
                category: category,
                amount: amount,
                month: _selectedMonth,
                year: _selectedYear,
              )));
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    final cs = Theme.of(context).colorScheme;
    final amountController = TextEditingController(text: budget.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: Text('Edit Budget ${budget.category}'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Jumlah Budget', prefixText: 'Rp '),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<BudgetBloc>().add(BudgetDeleteRequested(id: budget.safeId));
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: TextStyle(color: cs.error)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
              if (amount == null || amount <= 0) return;
              context.read<BudgetBloc>().add(BudgetUpdateRequested(budget: budget.copyWith(amount: amount)));
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  List<String> _getUnbudgetedCategories() {
    final budgetState = context.read<BudgetBloc>().state;
    final existing = budgetState is BudgetLoaded
        ? budgetState.getBudgetsForMonth(_selectedMonth, _selectedYear).map((b) => b.category).toSet()
        : <String>{};
    return DefaultCategories.list
        .where((c) => c.type == 'expense')
        .map((c) => c.name)
        .where((n) => !existing.contains(n))
        .toList();
  }
}
