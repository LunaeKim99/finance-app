import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/usage_provider.dart';
import '../services/ai_service.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/history_screen.dart';
import '../screens/upgrade_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/transaction_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _refreshRecommendation() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        final balance = provider.totalBalance;
        final income = provider.monthlyIncome;
        final expense = provider.monthlyExpense;

        final isIOS = Platform.isIOS;
        final monthFormat = DateFormat('MMMM', 'id_ID');
        final currentMonth = monthFormat.format(DateTime.now());
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Widget body = RefreshIndicator(
          onRefresh: () => provider.loadTransactions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!provider.isOnline) _buildOfflineBanner(isIOS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isIOS
                          ? [const Color(0xFF34C759), const Color(0xFF30B350)]
                          : [const Color(0xFF4CAF50), const Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentMonth,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              isIOS
                                  ? CupertinoIcons.money_dollar_circle_fill
                                  : Icons.account_balance_wallet,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isIOS
                              ? const Color(0xFFE8F5E9)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isIOS
                                  ? CupertinoIcons.arrow_down_circle_fill
                                  : Icons.arrow_downward,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(income),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isIOS
                              ? const Color(0xFFFFEBEE)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isIOS
                                  ? CupertinoIcons.arrow_up_circle_fill
                                  : Icons.arrow_upward,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(expense),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (isIOS) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 14,
                              color: isIOS
                                  ? CupertinoColors.activeBlue
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: isIOS
                                ? CupertinoColors.activeBlue
                                : const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (provider.allTransactions.isEmpty)
                  _buildEmptyState(context, isIOS)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.getRecentTransactions(5).length,
                    itemBuilder: (context, index) {
                      final transactions = provider.getRecentTransactions(5);
                      return TransactionCard(
                        transaction: transactions[index],
                        onTap: () =>
                            _navigateToEdit(context, transactions[index]),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                _buildBudgetRecommendation(),
              ],
            ),
          ),
        );

        if (isIOS) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage('assets/images/logo.png'),
                    height: 24,
                    width: 24,
                  ),
                  SizedBox(width: 8),
                  Text('UWANGKU'),
                ],
              ),
            ),
            child: SafeArea(child: body),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 36,
                  width: 36,
                ),
                const SizedBox(width: 8),
                const Text('UWANGKU'),
              ],
            ),
            centerTitle: false,
            actions: [
              if (AppConfig.isDemoBuild)
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Consumer<UsageProvider>(
                builder: (context, usageProvider, _) {
                  final isPremium = usageProvider.isPremium;
                  return GestureDetector(
                    onTap: () {
                      if (!isPremium) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpgradeScreen(),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.verified_user, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Premium'),
                              ],
                            ),
                            content: const Text(
                              'Kamu sudah Premium! Nikmati semua fitur tanpa batasan.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isPremium ? Colors.amber : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremium ? Icons.emoji_events : Icons.lock,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPremium ? 'PREMIUM' : 'FREE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: themeProvider.toggleTheme,
                  tooltip: themeProvider.isDarkMode
                      ? 'Mode Terang'
                      : 'Mode Gelap',
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildOfflineBanner(bool isIOS) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isIOS ? CupertinoIcons.wifi_slash : Icons.wifi_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          const Text(
            'Tidak ada koneksi internet',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isIOS) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIOS ? CupertinoIcons.doc_text : Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + untuk mulai mencatat keuanganmu',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  isIOS
                      ? CupertinoPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        )
                      : MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, TransactionModel transaction) {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) =>
              AddTransactionScreen(existingTransaction: transaction),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AddTransactionScreen(existingTransaction: transaction),
        ),
      );
    }
  }

  Widget _buildBudgetRecommendation() {
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);
    final isPremium = usageProvider.isPremium;
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final month = DateTime.now().month;
    final year = DateTime.now().year;
    final income = txProvider.getMonthlyIncomeByMonth(month, year);
    final expense = txProvider.getMonthlyExpenseByMonth(month, year);
    final categoryTotals = txProvider.getCategoryTotals(month, year);

    if (!isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Saran Keuangan AI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Fitur ini khusus pengguna Premium.\nDapatkan saran keuangan personal.',
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Upgrade ke Premium'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8),
                    Text(
                      'Saran Keuangan AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _refreshRecommendation,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: AiRecommendationService().generateBudgetRecommendation(
                categoryTotals: categoryTotals,
                totalIncome: income,
                totalExpense: expense,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Menganalisis...'),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Gagal: ${snapshot.error}');
                }
                return MarkdownBody(
                  data: snapshot.data ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
