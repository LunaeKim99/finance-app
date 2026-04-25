import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../screens/add_transaction_screen.dart';
import '../widgets/transaction_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final filteredTransactions = _getFilteredTransactions(provider.allTransactions);

        if (isIOS) {
          return _buildIOS(filteredTransactions, provider);
        }

        return _buildAndroid(filteredTransactions, provider);
      },
    );
  }

Widget _buildAndroid(List<TransactionModel> transactions, TransactionProvider provider) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          if (transactions.isNotEmpty) _buildStatsHeader(transactions),
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : _buildList(transactions, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildIOS(List<TransactionModel> transactions, TransactionProvider provider) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildTabBar(),
          if (transactions.isNotEmpty) _buildStatsHeader(transactions),
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : _buildList(transactions, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedTab,
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Semua'),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Pemasukan'),
            ),
            2: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Pengeluaran'),
            ),
          },
          onValueChanged: (value) => setState(() => _selectedTab = value!),
        ),
      );
    }

    final tabs = ['Semua', 'Pemasukan', 'Pengeluaran'];
    final tabColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF4CAF50),
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected ? tabColors[i] : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<TransactionModel> transactions) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);

    if (_selectedTab == 1) {
      return _buildSingleStatBar(
        icon: Icons.arrow_downward_rounded,
        color: const Color(0xFF4CAF50),
        label: '${transactions.length} transaksi pemasukan',
        amount: currencyFormat.format(totalIncome),
      );
    }

    if (_selectedTab == 2) {
      return _buildSingleStatBar(
        icon: Icons.arrow_upward_rounded,
        color: Colors.red,
        label: '${transactions.length} transaksi pengeluaran',
        amount: currencyFormat.format(totalExpense),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Pemasukan',
              amount: currencyFormat.format(totalIncome),
              color: const Color(0xFF4CAF50),
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.grey.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              label: 'Pengeluaran',
              amount: currencyFormat.format(totalExpense),
              color: Colors.red,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStatBar({
    required IconData icon,
    required Color color,
    required String label,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            amount,
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

  Widget _buildStatItem({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isIOS = Platform.isIOS;

    final messages = {
      0: ('Belum ada transaksi', 'Mulai catat pemasukan atau pengeluaranmu'),
      1: ('Belum ada pemasukan', 'Catat sumber penghasilanmu di sini'),
      2: ('Belum ada pengeluaran', 'Yuk mulai pantau pengeluaranmu'),
    };

    final (title, subtitle) = messages[_selectedTab]!;

    final emptyColor = _selectedTab == 2
        ? Colors.red
        : const Color(0xFF4CAF50);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: emptyColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOS
                    ? (_selectedTab == 2
                        ? CupertinoIcons.arrow_up_circle
                        : _selectedTab == 1
                            ? CupertinoIcons.arrow_down_circle
                            : CupertinoIcons.doc_text)
                    : (_selectedTab == 2
                        ? Icons.arrow_upward_rounded
                        : _selectedTab == 1
                            ? Icons.arrow_downward_rounded
                            : Icons.receipt_long_outlined),
                size: 36,
                color: emptyColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<TransactionModel> transactions, TransactionProvider provider) {
    final grouped = _groupByDate(transactions);
    final isIOS = Platform.isIOS;
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.toList()[index];
        final dateKey = entry.key;
        final items = entry.value;

        String dateLabel;
        if (dateKey == dateFormat.format(now)) {
          dateLabel = 'Hari ini';
        } else if (dateKey == dateFormat.format(yesterday)) {
          dateLabel = 'Kemarin';
        } else {
          dateLabel = dateKey;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((t) => isIOS
                ? _buildIOSListItem(t, provider)
                : _buildAndroidListItem(t, provider)),
          ],
        );
      },
    );
  }

  Map<String, List<TransactionModel>> _groupByDate(List<TransactionModel> transactions) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final Map<String, List<TransactionModel>> grouped = {};

    for (final t in transactions) {
      final dateKey = dateFormat.format(t.date);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    return grouped;
  }

  Widget _buildAndroidListItem(TransactionModel transaction, TransactionProvider provider) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteTransaction(transaction, provider),
      child: TransactionCard(
        transaction: transaction,
        showEditIcon: true,
        onTap: () => _navigateToEdit(transaction),
      ),
    );
  }

  Widget _buildIOSListItem(TransactionModel transaction, TransactionProvider provider) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDeleteIOS(transaction),
      onDismissed: (_) => _deleteTransaction(transaction, provider),
      child: CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEdit(transaction);
            },
            trailingIcon: CupertinoIcons.pencil,
            child: const Text('Edit'),
          ),
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteIOS(transaction).then((confirmed) {
                if (confirmed) {
                  _deleteTransaction(transaction, provider);
                }
              });
            },
            trailingIcon: CupertinoIcons.delete,
            child: const Text('Hapus'),
          ),
        ],
        child: TransactionCard(
          transaction: transaction,
          showEditIcon: true,
          onTap: () => _navigateToEdit(transaction),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteIOS(TransactionModel transaction) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    switch (_selectedTab) {
      case 1:
        return transactions.where((t) => t.type == 'income').toList();
      case 2:
        return transactions.where((t) => t.type == 'expense').toList();
      default:
        return transactions;
    }
  }

  void _deleteTransaction(TransactionModel transaction, TransactionProvider provider) async {
    await provider.deleteTransaction(transaction.id!);

    if (mounted) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Berhasil'),
            content: const Text('Transaksi berhasil dihapus'),
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
          SnackBar(
            content: const Text('Transaksi dihapus'),
            action: SnackBarAction(
              label: 'Batal',
              onPressed: () {
                provider.addTransaction(transaction);
              },
            ),
          ),
        );
      }
    }
  }

  void _navigateToEdit(TransactionModel transaction) {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AddTransactionScreen(
            existingTransaction: transaction,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(
            existingTransaction: transaction,
          ),
        ),
      );
    }
  }
}