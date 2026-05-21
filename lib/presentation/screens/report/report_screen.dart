import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/month_selector.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../export_import/export_screen.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_state.dart';
import '../upgrade/upgrade_screen.dart';
import 'bloc/report_bloc.dart';
import 'bloc/report_state.dart';
import 'bloc/report_event.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _showMonthlySummary = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
        }

        final month = _selectedMonth.month;
        final year = _selectedMonth.year;
        final income = state.getMonthlyIncomeByMonth(month, year);
        final expense = state.getMonthlyExpenseByMonth(month, year);
        final balance = income - expense;
        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    children: [
                      _buildMonthSelector(),
                      const SizedBox(height: 16),
                      _buildSummaryGrid(income, expense, balance, currencyFormat),
                      const SizedBox(height: 16),
                      _buildWeeklySummary(state, month, year, income, expense, currencyFormat),
                    ],
                  ),
                ),
              ],
            ),
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
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 48),
            const Spacer(),
            Text('Laporan', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
              icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return MonthSelector(
      selectedMonth: _selectedMonth,
      onPrevious: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
      onNext: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
      compact: true,
    );
  }

  Widget _buildSummaryGrid(double income, double expense, double balance, NumberFormat fmt) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
                          child: const Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Pemasukan', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rp', style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
                    Text(fmt.format(income), style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.1)),
                          child: const Icon(Icons.arrow_upward_rounded, color: AppColors.secondary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Pengeluaran', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rp', style: AppTypography.bodySm.copyWith(color: AppColors.secondary)),
                    Text(fmt.format(expense), style: AppTypography.headlineSm.copyWith(color: AppColors.secondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.surfaceContainerHighest),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Bersih', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    Text(fmt.format(balance), style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummary(TransactionLoaded state, int month, int year, double income, double expense, NumberFormat fmt) {
    final categoryTotals = state.getCategoryTotals(month, year);
    final topCategory = categoryTotals.entries.isNotEmpty
        ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.mdRadius),
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Ringkasan Mingguan', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dalam 7 hari terakhir, kamu memiliki total pengeluaran sebesar '
            '${fmt.format(expense)}. '
            '${topCategory != null ? "Pengeluaran terbesar kamu adalah pada kategori ${topCategory.key}, dengan total ${fmt.format(topCategory.value)}. " : ""}'
            'Sementara itu, kamu juga memiliki pendapatan sebesar '
            '${fmt.format(income)}.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 12),
          BlocBuilder<UsageBloc, UsageState>(
            builder: (context, usageState) {
              final isPremium = usageState is UsageLoaded ? usageState.isPremium : false;
              return BlocBuilder<ReportBloc, ReportState>(
                builder: (context, reportState) {
                  return _buildAiSummarySection(reportState, categoryTotals, income, expense, fmt, isPremium);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummarySection(ReportState reportState, Map<String, double> categoryTotals, double income, double expense, NumberFormat fmt, bool isPremium) {
    if (!isPremium) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Analisis AI (Premium)'),
        ),
      );
    }

    if (!_showMonthlySummary) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _showMonthlySummary = true);
            context.read<ReportBloc>().add(ReportGenerateAiSummary(
              categoryTotals: categoryTotals,
              totalIncome: income,
              totalExpense: expense,
            ));
          },
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Lihat Analisis AI'),
        ),
      );
    }

    if (reportState is! ReportLoaded) return const SizedBox.shrink();

    if (reportState.aiSummaryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Menganalisis...'),
          ]),
        ),
      );
    }

    if (reportState.aiSummary != null) {
      return MarkdownBody(
        data: reportState.aiSummary!,
        styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14)),
      );
    }

    return const SizedBox.shrink();
  }
}
