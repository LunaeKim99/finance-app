import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/payment_model.dart';
import '../providers/usage_provider.dart';
import '../services/midtrans_service.dart';
import 'payment_webview_screen.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  PremiumPlan _selectedPlan = PremiumPlan.monthly;
  bool _isLoading = false;
  String? _loadingMessage;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final usageProvider = context.watch<UsageProvider>();
    final isPremium = usageProvider.isPremium;
    final isIOS = Platform.isIOS;

    if (isPremium) {
      return _buildAlreadyPremium(isIOS);
    }

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Upgrade ke Premium'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ),
        child: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade ke Premium'),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildAlreadyPremium(bool isIOS) {
    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Premium'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 80,
                  color: Colors.amber,
                ),
                SizedBox(height: 16),
                Text(
                  'Kamu sudah Premium!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('Nikmati semua fitur tanpa batasan'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.verified_user,
              size: 80,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'Kamu sudah Premium!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Nikmati semua fitur tanpa batasan'),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isIOS = Platform.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/logo_uwangku.png',
            height: 80,
            width: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Upgrade ke Premium',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nikmati semua fitur tanpa batasan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          _buildFeatureList(),
          const SizedBox(height: 32),
          _buildPlanSelector(isIOS),
          const SizedBox(height: 24),
          _buildPayButton(isIOS),
          const SizedBox(height: 24),
          const Text(
            '🔒 Pembayaran aman via Midtrans',
            style: TextStyle(color: Colors.grey),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            if (_loadingMessage != null) Text(_loadingMessage!),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      '✅ AI Input Tanpa Batas',
      '✅ Scan Struk Tanpa Batas',
      '✅ Ringkasan Keuangan AI',
      '✅ Saran Budget Personal',
      '✅ Export PDF & Excel',
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(f, style: const TextStyle(fontSize: 16)),
      )).toList(),
    );
  }

  Widget _buildPlanSelector(bool isIOS) {
    final monthlyPrice = MidtransService.planPrices[PremiumPlan.monthly]!;
    final lifetimePrice = MidtransService.planPrices[PremiumPlan.yearly]!;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedPlan = PremiumPlan.monthly),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _selectedPlan == PremiumPlan.monthly
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPlan == PremiumPlan.monthly
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  color: _selectedPlan == PremiumPlan.monthly
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium Bulanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(monthlyPrice),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedPlan == PremiumPlan.monthly)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedPlan = PremiumPlan.yearly),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedPlan == PremiumPlan.yearly
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPlan == PremiumPlan.yearly
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: _selectedPlan == PremiumPlan.yearly
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Premium Tahunan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TERPOPULER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _currencyFormat.format(lifetimePrice),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hemat 71%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_selectedPlan == PremiumPlan.yearly)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(bool isIOS) {
    if (_isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(12),
        onPressed: _processPayment,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.creditcard),
            SizedBox(width: 8),
            Text(
              'Bayar Sekarang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card),
            SizedBox(width: 8),
            Text(
              'Bayar Sekarang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Menyiapkan pembayaran...';
    });

    try {
      final midtransService = MidtransService();

      if (!midtransService.isConfigured) {
        throw Exception('Midtrans belum dikonfigurasi. Tambahkan keys di file .env');
      }

      final orderId = midtransService.generateOrderId();
      final amount = MidtransService.planPrices[_selectedPlan]!.toDouble();

      setState(() => _loadingMessage = 'Menghubungi Midtrans...');

      final snapToken = await midtransService.createSnapToken(
        orderId: orderId,
        amount: amount,
        customerName: 'Pengguna UWANGKU',
        customerEmail: 'user@uwangku.com',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        final result = await Navigator.push<PaymentStatus>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebviewScreen(snapToken: snapToken),
          ),
        );

        if (result == PaymentStatus.success && mounted) {
          _showSuccessDialog();
        } else if (result == PaymentStatus.failed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran gagal. Silakan coba lagi.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('Selamat! 🎉'),
          ],
        ),
        content: const Text('Kamu sekarang pengguna Premium!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Mulai Gunakan'),
          ),
        ],
      ),
    );
  }
}