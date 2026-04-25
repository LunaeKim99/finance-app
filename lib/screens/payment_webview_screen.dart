import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/payment_model.dart';
import '../providers/usage_provider.dart';
import '../services/midtrans_service.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String snapToken;
  final VoidCallback? onSuccess;

  const PaymentWebviewScreen({
    super.key,
    required this.snapToken,
    this.onSuccess,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledResult = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final midtransService = MidtransService();
    final url = midtransService.getSnapUrl(widget.snapToken);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkPaymentResult(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _checkPaymentResult(String url) {
    if (_hasHandledResult) return;

    final urlLower = url.toLowerCase();

    if (urlLower.contains('payment_status=settlement') ||
        urlLower.contains('transaction_status=settlement') ||
        urlLower.contains('status=success') ||
        urlLower.contains('success=true')) {
      _handleSuccess();
    } else if (urlLower.contains('payment_status=pending') ||
        urlLower.contains('transaction_status=pending') ||
        urlLower.contains('status=pending')) {
      _handlePending();
    } else if (urlLower.contains('payment_status=deny') ||
        urlLower.contains('transaction_status=deny') ||
        urlLower.contains('status=failure') ||
        urlLower.contains('failure')) {
      _handleFailed();
    }
  }

  Future<void> _handleSuccess() async {
    if (_hasHandledResult) return;
    _hasHandledResult = true;

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final usageProvider = context.read<UsageProvider>();
      await usageProvider.upgradeToPremium();

      if (mounted) {
        Navigator.pop(context, PaymentStatus.success);
      }
    }
  }

  void _handlePending() {
    if (_hasHandledResult) return;
    _hasHandledResult = true;
    
    Navigator.pop(context, PaymentStatus.pending);
  }

  void _handleFailed() {
    if (_hasHandledResult) return;
    _hasHandledResult = true;

    Navigator.pop(context, PaymentStatus.failed);
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Pembayaran Premium'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context, PaymentStatus.cancelled),
            child: const Icon(CupertinoIcons.xmark),
          ),
        ),
        child: _buildContent(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Premium'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, PaymentStatus.cancelled),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}