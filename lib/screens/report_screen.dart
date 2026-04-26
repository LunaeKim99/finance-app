import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/usage_provider.dart';
import '../services/ai_service.dart';
import '../screens/export_screen.dart';
import '../screens/upgrade_screen.dart';
import '../utils/app_theme.dart';

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
    final isIOS = Platform.isIOS;

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final month = _selectedMonth.month;
        final year = _selectedMonth.year;

        final income = provider.getMonthlyIncomeByMonth(month, year);
        final expense = provider.getMonthlyExpenseByMonth(month, year);
        final balance = income - expense;
        final categoryTotals = provider.getCategoryTotals(month, year);

        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        Widget body = SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            child: Column(
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildSummaryCards(income, expense, balance, currencyFormat),
                const SizedBox(height: 24),
                _buildDailySummary(provider),
                const SizedBox(height: 24),
                _buildWeeklySummary(provider),
                const SizedBox(height: 24),
                _buildMonthlySummary(provider),
                const SizedBox(height: 24),
                _buildPieChart(categoryTotals, currencyFormat),
                const SizedBox(height: 24),
                _buildBarChart(provider),
              ],
            ),
          ),
        );

        if (isIOS) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Laporan'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                ),
                child: const Icon(CupertinoIcons.share),
              ),
            ),
            child: body,
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final isIOS = Platform.isIOS;
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');

    if (isIOS) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _prevMonth,
              child: const Icon(CupertinoIcons.chevron_left),
            ),
            const SizedBox(width: 16),
            Text(
              monthFormat.format(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _nextMonth,
              child: const Icon(CupertinoIcons.chevron_right),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCard
              : Colors.grey,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 16),
            Text(
              monthFormat.format(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    double income,
    double expense,
    double balance,
    NumberFormat currencyFormat,
  ) {
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF4CAF50);
    const red = Colors.red;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                'Pemasukan',
                currencyFormat.format(income),
                green,
                isDark ? AppTheme.darkCard : green.withValues(alpha: 0.05),
                isIOS ? CupertinoIcons.arrow_down_circle_fill : Icons.arrow_downward,
                gradient: LinearGradient(
                  colors: [green.withValues(alpha: 0.15), green.withValues(alpha: 0.05)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                'Pengeluaran',
                currencyFormat.format(expense),
                red,
                isDark ? AppTheme.darkCard : red.withValues(alpha: 0.05),
                isIOS ? CupertinoIcons.arrow_up_circle_fill : Icons.arrow_upward,
                gradient: LinearGradient(
                  colors: [red.withValues(alpha: 0.15), red.withValues(alpha: 0.05)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          'Saldo Bersih',
          currencyFormat.format(balance),
          balance >= 0 ? green : red,
          isDark ? AppTheme.darkCard : const Color(0xFFE8F5E9),
          isIOS ? CupertinoIcons.money_dollar_circle_fill : Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildCard(
    String title,
    String value,
    Color textColor,
    Color backgroundColor,
    IconData icon, {
    LinearGradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? backgroundColor : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals, NumberFormat currencyFormat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (categoryTotals.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pie_chart_outline, size: 24, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada data pengeluaran',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
    ];

    final sections = categoryTotals.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      return PieChartSectionData(
        value: amount,
        title: category,
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pengeluaran per Kategori'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: categoryTotals.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$category (${currencyFormat.format(amount)})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart(TransactionProvider provider) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<BarChartGroupData> barGroups = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final income = provider.getMonthlyIncomeByMonth(month.month, month.year);
      final expense = provider.getMonthlyExpenseByMonth(month.month, month.year);

      barGroups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: const Color(0xFF4CAF50),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.red,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pemasukan vs Pengeluaran (6 Bulan Terakhir)'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final month = DateTime(now.year, now.month - (5 - value.toInt()));
                            return Text(
                              DateFormat('MMM').format(month),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Pemasukan', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummary(TransactionProvider provider) {
    final usageProvider = context.watch<UsageProvider>();
    final isPremium = usageProvider.isPremium;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isPremium) {
      const green = Color(0xFF4CAF50);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [green.withValues(alpha: 0.08), green.withValues(alpha: 0.03)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: green.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ringkasan Mingguan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur ini khusus pengguna Premium.\nDapatkan ringkasan naratif keuangan mingguan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
              ),
              child: const Text('Upgrade ke Premium'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<String>(
      future: AiRecommendationService().generateWeeklySummary(
        provider.allTransactions,
      ),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.summarize, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Text(
                    'Ringkasan Mingguan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Menganalisis transaksi...'),
                    ],
                  ),
                )
              else if (snapshot.hasError)
                Text('Gagal: ${snapshot.error}')
              else
                MarkdownBody(
                  data: snapshot.data ?? '',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailySummary(TransactionProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isIOS = Platform.isIOS;

    final todayTransactions = provider.allTransactions.where((t) {
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      return txDate == today;
    }).toList();

    double todayIncome = 0;
    double todayExpense = 0;
    for (final tx in todayTransactions) {
      if (tx.type == 'income') {
        todayIncome += tx.amount;
      } else {
        todayExpense += tx.amount;
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dayFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ringkasan Hari Ini'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF5F9F5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isIOS
                        ? CupertinoIcons.calendar
                        : Icons.calendar_today_rounded,
                    size: 16,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dayFormat.format(now),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDailyStatCard(
                      label: 'Pemasukan',
                      value: currencyFormat.format(todayIncome),
                      color: const Color(0xFF4CAF50),
                      icon: isIOS
                          ? CupertinoIcons.arrow_down_circle_fill
                          : Icons.arrow_downward_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDailyStatCard(
                      label: 'Pengeluaran',
                      value: currencyFormat.format(todayExpense),
                      color: Colors.red,
                      icon: isIOS
                          ? CupertinoIcons.arrow_up_circle_fill
                          : Icons.arrow_upward_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (todayTransactions.isEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 24, color: Color(0xFF4CAF50)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  '${todayTransactions.length} Transaksi Hari Ini',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...todayTransactions.take(5).map((tx) {
                  final isExpense = tx.type == 'expense';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isExpense
                                ? Colors.red.withValues(alpha: 0.1)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpense
                                ? (isIOS
                                    ? CupertinoIcons.arrow_up_circle
                                    : Icons.arrow_upward_rounded)
                                : (isIOS
                                    ? CupertinoIcons.arrow_down_circle
                                    : Icons.arrow_downward_rounded),
                            size: 18,
                            color: isExpense
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (tx.note.isNotEmpty)
                                Text(
                                  tx.note,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isExpense
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (todayTransactions.length > 5)
                  Center(
                    child: Text(
                      '... dan ${todayTransactions.length - 5} transaksi lainnya',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(TransactionProvider provider) {
    final usageProvider = context.watch<UsageProvider>();
    final isPremium = usageProvider.isPremium;
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isPremium) {
      const green = Color(0xFF4CAF50);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [green.withValues(alpha: 0.08), green.withValues(alpha: 0.03)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: green.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ringkasan Bulanan AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Dapatkan analisis mendalam keuangan bulan ini '
              'dengan rekomendasi dari AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            isIOS
                ? CupertinoButton.filled(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    ),
                    child: const Text('Upgrade ke Premium'),
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                    ),
                    child: const Text('Upgrade ke Premium'),
                  ),
          ],
        ),
      );
    }

    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ringkasan Bulanan AI'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (!_showMonthlySummary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _showMonthlySummary = true),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate Ringkasan Bulan Ini'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                FutureBuilder<String>(
                  key: ValueKey(
                    'monthly_${_selectedMonth.month}_${_selectedMonth.year}',
                  ),
                  future: AiRecommendationService().generateMonthlySummary(
                    provider.allTransactions
                        .where((t) =>
                            t.date.month == _selectedMonth.month &&
                            t.date.year == _selectedMonth.year)
                        .toList(),
                    monthName,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : const Color(0xFFF9FBF9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'AI sedang menganalisis...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 6),
                            Text(
                              'Gagal: ${snapshot.error}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _showMonthlySummary = false;
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => setState(
                                    () => _showMonthlySummary = true,
                                  ),
                                );
                              }),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MarkdownBody(
                        data: snapshot.data ?? '',
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _showMonthlySummary = false;
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        _showMonthlySummary = false;
      });
    }
  }
}