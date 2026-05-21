import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/segmented_pill_control.dart';
import '../../widgets/transaction/transaction_card.dart';
import 'bloc/transaction_bloc.dart';
import 'bloc/transaction_state.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
        }

        final filtered = _getFilteredTransactions(state.transactions);
        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final paginated = _getPaginatedTransactions(filtered);
        final grouped = _groupByDate(paginated);

        return Scaffold(
          body: Column(
            children: [
              _buildHeader(),
              _buildFilterTabs(),
              _buildSummaryRow(state, currencyFormat),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        children: [
                          _buildAddButton(),
                          const SizedBox(height: 8),
                          ...grouped.entries.map((e) => _buildDateGroup(e.key, e.value, currencyFormat)),
                          _buildPaginationControls(filtered.length),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text('Riwayat Transaksi', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: SegmentedPillControl(
        labels: const ['Semua', 'Pemasukan', 'Pengeluaran'],
        selectedIndex: _selectedTab,
        onChanged: (i) => setState(() { _selectedTab = i; _currentPage = 0; }),
      ),
    );
  }

  Widget _buildSummaryRow(TransactionLoaded state, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('Pemasukan', style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(fmt.format(state.monthlyIncome), style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.1)),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.secondary, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('Pengeluaran', style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(fmt.format(state.monthlyExpense), style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String label, List<Transaction> txs, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        ),
        ...txs.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TransactionCard(transaction: tx, showEditIcon: true, onTap: () => _navigateToEdit(tx)),
        )),
      ],
    );
  }

  Widget _buildAddButton() {
    return GlassCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Tambah Transaksi', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.08)),
            child: Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text('Belum ada transaksi', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Mulai catat pengeluaran atau pemasukan', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  List<Transaction> _getPaginatedTransactions(List<Transaction> filtered) {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Widget _buildPaginationControls(int totalItems) {
    final totalPages = (totalItems / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
            disabledColor: AppColors.onSurfaceVariant,
          ),
          Text(
            '${_currentPage + 1} / $totalPages',
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.primary,
            disabledColor: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> all) {
    switch (_selectedTab) {
      case 1:
        return all.where((t) => t.type == TransactionType.income).toList();
      case 2:
        return all.where((t) => t.type == TransactionType.expense).toList();
      default:
        return all;
    }
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    final Map<String, List<Transaction>> groups = {};
    for (final tx in txs) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (txDate == today) {
        label = 'Hari ini';
      } else if (txDate == yesterday) {
        label = 'Kemarin';
      } else {
        label = dateFormat.format(tx.date);
      }
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  void _navigateToEdit(Transaction tx) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(existingTransaction: tx)));
  }
}
