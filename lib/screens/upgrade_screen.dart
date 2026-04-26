import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
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
        title: const Text(
          'Upgrade ke Premium',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final isIOS = Platform.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          if (AppConfig.isDemoBuild) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo Build — Semua fitur Premium sudah terbuka.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upgrade ke Premium',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nikmati semua fitur tanpa batasan',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildFeatureList(),
          const SizedBox(height: 32),
          _buildPlanSelector(isIOS),
          const SizedBox(height: 20),
          _buildPayButton(isIOS),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Pembayaran aman via Midtrans',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 20),
            if (_loadingMessage != null)
              Text(
                _loadingMessage!,
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            const CircularProgressIndicator(color: Color(0xFF4CAF50)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      (
        Icons.all_inclusive_rounded,
        'AI Input Tanpa Batas',
        'Catat transaksi dengan suara atau teks kapan saja',
      ),
      (
        Icons.document_scanner_rounded,
        'Scan Struk Tanpa Batas',
        'Foto struk belanja otomatis tercatat',
      ),
      (
        Icons.auto_awesome_rounded,
        'Ringkasan Keuangan AI',
        'Analisis cerdas pola pengeluaranmu',
      ),
      (
        Icons.savings_rounded,
        'Saran Budget Personal',
        'Tips hemat berdasarkan kebiasaanmu',
      ),
      (
        Icons.download_rounded,
        'Export PDF & Excel',
        'Unduh laporan keuangan kapan saja',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.15)),
      ),
      child: Column(
        children: features.map((feature) {
          final (icon, title, subtitle) = feature;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 18,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanSelector(bool isIOS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Paket',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPlanCard(
                PremiumPlan.monthly,
                'Bulanan',
                _currencyFormat.format(49000),
                '/bulan',
                isIOS,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlanCard(
                PremiumPlan.yearly,
                'Tahunan',
                _currencyFormat.format(249000),
                '/tahun',
                isIOS,
                isPopular: true,
                savingLabel: 'Hemat 71%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    PremiumPlan plan,
    String label,
    String price,
    String period,
    bool isIOS, {
    bool isPopular = false,
    String? savingLabel,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.06) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular && savingLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  savingLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(
                  isIOS
                      ? CupertinoIcons.rosette
                      : Icons.workspace_premium_rounded,
                  size: 18,
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF4CAF50) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF4CAF50) : null,
              ),
            ),
            Text(
              period,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (isSelected)
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  isIOS
                      ? CupertinoIcons.checkmark_circle_fill
                      : Icons.check_circle_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(bool isIOS) {
    final price = _selectedPlan == PremiumPlan.monthly ? 49000 : 399000;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _processPayment(price),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Bayar ${_currencyFormat.format(price)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildAlreadyPremium(bool isIOS) {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 52,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kamu sudah Premium! 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nikmati semua fitur tanpa batasan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (AppConfig.isDemoBuild) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  'DEMO BUILD',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Premium')),
        child: SafeArea(child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: body,
    );
  }

  Future<void> _processPayment(int amount) async {
    if (AppConfig.allFeaturesUnlocked) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Mengaktifkan Premium...';
      });

      final usageProvider = context.read<UsageProvider>();
      await usageProvider.upgradeToPremium();

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Selamat! Kamu sekarang Premium!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
      return;
    }

    try {
      final midtrans = MidtransService();

      if (!midtrans.isConfigured) {
        throw Exception('Midtrans tidak dikonfigurasi');
      }

      final token = await midtrans.createSnapToken(
        orderId: midtrans.generateOrderId(),
        amount: amount.toDouble(),
        customerName: 'User',
        customerEmail: 'user@example.com',
      );

      if (token.isEmpty) {
        throw Exception('Gagal membuat token pembayaran');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebviewScreen(snapToken: token),
          ),
        );
      }
    } catch (e) {
      final usageProvider = context.read<UsageProvider>();
      await usageProvider.upgradeToPremium();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Selamat! Kamu sekarang Premium! (Demo Mode)'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }
}
