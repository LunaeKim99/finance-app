import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/receipt_scan_result.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/usage_provider.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final ReceiptScanResult scanResult;

  const ReceiptReviewScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late List<ReceiptItem> _items;
  bool _isSingleTransaction = true;
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<String> _categories = [
    'Makanan',
    'Minuman',
    'Kebersihan',
    'Elektronik',
    'Pakaian',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _items = widget.scanResult.items.map((item) => item).toList();
    if (_items.isEmpty) {
      _items = [
        ReceiptItem(
          name: widget.scanResult.merchant.isNotEmpty
              ? widget.scanResult.merchant
              : 'Item',
          price: widget.scanResult.total,
          category: 'Lainnya',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Review Struk'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _confirmAndSave,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : const Text('Simpan'),
          ),
        ),
        child: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Struk'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _confirmAndSave,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildToggle(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _buildItemCard(index);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildTotalAndButtons(),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    final totalStr = _currencyFormat.format(_calculateTotal());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (widget.scanResult.merchant.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.store, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.scanResult.merchant,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSingleTransaction = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isSingleTransaction
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '1 Transaksi (Total: $totalStr)',
                      style: TextStyle(
                        color: _isSingleTransaction
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSingleTransaction = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isSingleTransaction
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_items.length} Item (per item)',
                      style: TextStyle(
                        color: !_isSingleTransaction
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final isIOS = Platform.isIOS;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _currencyFormat.format(item.price),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isIOS && Platform.isIOS == false)
              DropdownButtonFormField<String>(
                value: item.category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  isDense: true,
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _items[index] = item.copyWith(category: value);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAndButtons() {
    final totalStr = _currencyFormat.format(_calculateTotal());
    final isIOS = Platform.isIOS;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              totalStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: isIOS
                  ? CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: Colors.grey,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Scan Ulang'),
                    )
                  : OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Scan Ulang'),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isIOS
                  ? CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: const Color(0xFF4CAF50),
                      onPressed: _isLoading ? null : _confirmAndSave,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text('Konfirmasi & Simpan'),
                    )
                  : ElevatedButton(
                      onPressed: _isLoading ? null : _confirmAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Konfirmasi & Simpan'),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateTotal() {
    if (_isSingleTransaction) {
      return widget.scanResult.total;
    }
    return _items.fold(0, (sum, item) => sum + item.price);
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isLoading = true);

    try {
      final txProvider = context.read<TransactionProvider>();
      final usageProvider = context.read<UsageProvider>();

      if (_isSingleTransaction) {
        final total = _calculateTotal();
        final transaction = TransactionModel(
          title: widget.scanResult.merchant.isNotEmpty
              ? widget.scanResult.merchant
              : ' Pembelian',
          amount: total,
          type: 'expense',
          category: _items.isNotEmpty ? _items.first.category : 'Lainnya',
          date: widget.scanResult.date ?? DateTime.now(),
          note: 'Dari scan struk',
        );
        await txProvider.addTransaction(transaction);
      } else {
        for (final item in _items) {
          final transaction = TransactionModel(
            title: item.name,
            amount: item.price,
            type: 'expense',
            category: item.category,
            date: widget.scanResult.date ?? DateTime.now(),
            note: 'Dari scan struk',
          );
          await txProvider.addTransaction(transaction);
        }
      }

      await usageProvider.incrementAiPhoto();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil disimpan!'),
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}