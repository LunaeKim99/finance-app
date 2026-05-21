import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../domain/entities/transaction.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/transaction/transaction_card.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_state.dart';
import '../transaction/bloc/transaction_event.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/history_screen.dart';
import '../budget/budget_screen.dart';
import '../budget/bloc/budget_bloc.dart';
import '../budget/bloc/budget_state.dart';
import '../upgrade/upgrade_screen.dart';
import '../../../data/datasources/remote/ai_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _refreshRecommendation() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
        }

        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final balance = state.totalBalance;
        final income = state.monthlyIncome;
        final expense = state.monthlyExpense;
        final monthFormat = DateFormat('MMMM', 'id_ID');
        final currentMonth = monthFormat.format(DateTime.now());

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(const TransactionLoadRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildTopAppBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!state.isOnline) _buildOfflineNotice(),
                        const SizedBox(height: 16),
                        _buildBalanceCard(balance, currencyFormat, currentMonth),
                        const SizedBox(height: 16),
                        _buildSummaryRow(income, expense, currencyFormat),
                        const SizedBox(height: 16),
                        _buildBudgetSection(state, currencyFormat),
                        const SizedBox(height: 8),
                        _buildRecentTransactionsHeader(),
                        const SizedBox(height: 12),
                        if (state.transactions.isEmpty)
                          _buildEmptyState()
                        else
                          ...state.getRecentTransactions(5).map(
                            (tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionCard(
                                transaction: tx,
                                onTap: () => _navigateToEdit(tx),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _buildAiRecommendationSection(state),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Uwangku', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
              const Spacer(),
              BlocBuilder<UsageBloc, UsageState>(
                builder: (context, usageState) {
                  final isPremium = usageState is UsageLoaded ? usageState.isPremium : false;
                  return GestureDetector(
                    onTap: () {
                      if (!isPremium) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPremium ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.fullRadius,
                        border: !isPremium ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremium ? Icons.verified_rounded : Icons.stars_rounded,
                            size: 14,
                            color: isPremium ? AppColors.onPrimary : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isPremium ? 'Premium' : 'Premium',
                              style: AppTypography.labelMono.copyWith(
                                fontSize: 10,
                                color: isPremium ? AppColors.onPrimary : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, ss) {
                  final isDark = ss is SettingsLoaded && ss.settings.isDarkMode;
                  return InkWell(
                    onTap: () => context.read<SettingsBloc>().add(const SettingsToggleDarkMode()),
                    borderRadius: AppRadius.fullRadius,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer, borderRadius: AppRadius.fullRadius,
                      ),
                      child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showLogoutDialog(),
                borderRadius: AppRadius.fullRadius,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer, borderRadius: AppRadius.fullRadius,
                  ),
                  child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed.withValues(alpha: 0.2),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.tertiaryFixedDim.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.tertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OFFLINE', style: AppTypography.labelMono.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Koneksi terputus. Data mungkin tidak sinkron.', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, NumberFormat fmt, String month) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.premiumGradientStart, AppColors.premiumGradientMid, AppColors.premiumGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60, top: -60,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            left: -40, bottom: -40,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryFixed.withValues(alpha: 0.15)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Total Saldo', style: AppTypography.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppRadius.fullRadius,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Bln', style: AppTypography.labelMono.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(width: 4),
                        Text(month.substring(0, 3), style: AppTypography.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(fmt.format(balance), style: AppTypography.currencyDisplay.copyWith(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense, NumberFormat fmt) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.mdRadius),
                  child: const Icon(Icons.south_east_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 12),
                Text('Pemasukan', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
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
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: AppRadius.mdRadius),
                  child: const Icon(Icons.north_east_rounded, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(height: 12),
                Text('Pengeluaran', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(fmt.format(expense), style: AppTypography.headlineSm.copyWith(color: AppColors.secondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(TransactionLoaded state, NumberFormat fmt) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        if (budgetState is! BudgetLoaded) return const SizedBox.shrink();

        final now = DateTime.now();
        final budgets = budgetState.getBudgetsForMonth(now.month, now.year);

        if (budgets.isEmpty) return const SizedBox.shrink();

        final categoryTotals = state.getCategoryTotals(now.month, now.year);
        final sorted = budgets.map((b) => MapEntry(b, categoryTotals[b.category] ?? 0.0)).toList()
          ..sort((a, b) => (b.value / b.key.amount).compareTo(a.value / a.key.amount));
        final top = sorted.take(3).toList();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget Bulan Ini', style: AppTypography.textTheme.titleMedium!.copyWith(color: AppColors.onSurface)),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
                    borderRadius: AppRadius.mdRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text('Lihat Semua', style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...top.map((e) => _miniBudgetRow(e.key.category, e.key.amount, e.value, fmt)),
            ],
          ),
        );
      },
    );
  }

  Widget _miniBudgetRow(String category, double budget, double spent, NumberFormat fmt) {
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = spent >= budget && budget > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
              Text('${fmt.format(spent)} / ${fmt.format(budget)}',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.fullRadius,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(isOver ? AppColors.error : AppColors.primary),
            ),
          ),
          if (isOver)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Melebihi budget!', style: AppTypography.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Transaksi Terbaru', style: AppTypography.textTheme.titleMedium!.copyWith(color: AppColors.onSurface)),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            borderRadius: AppRadius.mdRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text('Lihat Semua', style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.08)),
              child: Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('Belum ada transaksi', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text('Tap + untuk mulai mencatat', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRecommendationSection(TransactionLoaded state) {
    return BlocBuilder<UsageBloc, UsageState>(
      builder: (context, usageState) {
        final isPremium = usageState is UsageLoaded ? usageState.isPremium : false;
        final month = DateTime.now().month;
        final year = DateTime.now().year;
        final income = state.getMonthlyIncomeByMonth(month, year);
        final expense = state.getMonthlyExpenseByMonth(month, year);
        final categoryTotals = state.getCategoryTotals(month, year);

        if (!isPremium) {
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.mdRadius),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saran Keuangan AI', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                        Text('Khusus pengguna Premium', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                    child: const Text('Upgrade ke Premium', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Saran Keuangan AI', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _refreshRecommendation,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: AiRecommendationService().generateBudgetRecommendation(
                  categoryTotals: categoryTotals, totalIncome: income, totalExpense: expense,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Menganalisis...')]),
                      ),
                    );
                  }
                  if (snapshot.hasError) return Text('Gagal: ${snapshot.error}', style: AppTypography.bodySm.copyWith(color: AppColors.error));
                  return MarkdownBody(data: snapshot.data ?? '', styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEdit(Transaction tx) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(existingTransaction: tx)));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); context.read<AuthBloc>().add(const AuthLogoutRequested()); },
            child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
