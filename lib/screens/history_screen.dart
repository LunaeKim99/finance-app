import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
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
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: transactions.isEmpty ? _buildEmptyState() : _buildList(transactions, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildIOS(List<TransactionModel> transactions, TransactionProvider provider) {
    return SafeArea(
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: transactions.isEmpty ? _buildEmptyState() : _buildList(transactions, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoSlidingSegmentedControl<int>(
        groupValue: _selectedTab,
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Semua'),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pemasukan'),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pengeluaran'),
          ),
        },
        onValueChanged: (value) {
          setState(() {
            _selectedTab = value!;
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Semua')),
          ButtonSegment(value: 1, label: Text('Pemasukan')),
          ButtonSegment(value: 2, label: Text('Pengeluaran')),
        ],
        selected: {_selectedTab},
        onSelectionChanged: (selection) {
          setState(() {
            _selectedTab = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildList(List<TransactionModel> transactions, TransactionProvider provider) {
    final isIOS = Platform.isIOS;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        if (isIOS) {
          return _buildIOSListItem(transaction, provider);
        }

        return _buildAndroidListItem(transaction, provider);
      },
    );
  }

  Widget _buildAndroidListItem(TransactionModel transaction, TransactionProvider provider) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _deleteTransaction(transaction, provider),
      child: TransactionCard(transaction: transaction),
    );
  }

  Widget _buildIOSListItem(TransactionModel transaction, TransactionProvider provider) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          CupertinoIcons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) => _confirmDeleteIOS(transaction),
      onDismissed: (_) => _deleteTransaction(transaction, provider),
      child: TransactionCard(transaction: transaction),
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

  Widget _buildEmptyState() {
    final isIOS = Platform.isIOS;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIOS ? CupertinoIcons.doc_text : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
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
}