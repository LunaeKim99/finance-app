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
        title: const Text('Upgrade ke Premium'),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final isIOS = Platform.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (AppConfig.isDemoBuild) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.15),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo Build — Semua fitur Premium sudah terbuka. '
                      'Pembayaran menggunakan Midtrans Sandbox.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/logo.png',
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
      children: features
          .map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(f, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
    );
  }

  Widget _buildPlanSelector(bool isIOS) {
    return Row(
      children: [
        Expanded(
          child: _buildPlanCard(
            PremiumPlan.monthly,
            'Bulanan',
            _currencyFormat.format(29000),
            isIOS,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPlanCard(
            PremiumPlan.yearly,
            'Tahunan',
            _currencyFormat.format(99000),
            isIOS,
            isPopular: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    PremiumPlan plan,
    String label,
    String price,
    bool isIOS, {
    bool isPopular = false,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'HEMAT 71%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF4CAF50) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(price),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(bool isIOS) {
    final price = _selectedPlan == PremiumPlan.monthly ? 29000 : 99000;

    if (isIOS) {
      return CupertinoButton(
        color: const Color(0xFF4CAF50),
        onPressed: _isLoading ? null : () => _processPayment(price),
        child: _isLoading
            ? const CupertinoActivityIndicator()
            : Text('Bayar ${_currencyFormat.format(price)}'),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _isLoading ? null : () => _processPayment(price),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Bayar ${_currencyFormat.format(price)}'),
    );
  }

Future<void> _processPayment(int amount) async {
    // Demo mode: directly upgrade without payment
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

    // Real payment when not in demo mode
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
            builder: (_) => PaymentWebviewScreen(
              snapToken: token,
            ),
          ),
        );
      }
    } catch (e) {
      // Demo mode fallback
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
              children: [
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
                if (AppConfig.isDemoBuild) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DEMO BUILD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
          children: [
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
            if (AppConfig.isDemoBuild) ...[
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'DEMO BUILD',
                  style: TextStyle(
                    color: Colors.white,
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
  }
}