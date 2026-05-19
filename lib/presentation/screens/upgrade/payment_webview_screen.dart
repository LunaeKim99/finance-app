import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../data/models/payment_model.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_event.dart';
import '../../../data/datasources/remote/midtrans_service.dart';
import '../../../services/pb_client.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String snapToken;
  final String? planName;
  final VoidCallback? onSuccess;

  const PaymentWebviewScreen({
    super.key,
    required this.snapToken,
    this.planName,
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

  Future<void> _saveMidtransLog(Map<String, dynamic> data) async {
    try {
      final pb = PbClient.instance;
      final grossAmount = double.tryParse(data['gross_amount']?.toString() ?? '0') ?? 0;
      final transactionStatus = data['transaction_status']?.toString() ?? '';

      String status = 'pending';
      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        status = 'paid';
      } else if (transactionStatus == 'deny' || transactionStatus == 'failure') {
        status = 'failed';
      } else if (transactionStatus == 'expire') {
        status = 'expired';
      } else if (transactionStatus == 'cancel') {
        status = 'cancel';
      }

      await pb.collection('midtrans_logs').create(body: {
        'order_id': data['order_id']?.toString() ?? '',
        'transaction_id': data['transaction_id']?.toString() ?? '',
        'status': status,
        'payment_type': data['payment_type']?.toString() ?? '',
        'gross_amount': grossAmount,
        'currency': data['currency']?.toString() ?? 'IDR',
        'user_id': pb.authStore.model?.id,
        'raw_payload': data,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('[PaymentWebview] Midtrans log saved, status: $status');
    } catch (e) {
      debugPrint('[PaymentWebview] Error saving midtrans log: $e');
    }
  }

  Future<void> _savePremiumTransaction(Map<String, dynamic> midtransData) async {
    try {
      final pb = PbClient.instance;
      final grossAmount = double.tryParse(midtransData['gross_amount']?.toString() ?? '0') ?? 0;
      final orderId = midtransData['order_id']?.toString() ?? '';
      final transactionId = midtransData['transaction_id']?.toString() ?? '';

      await pb.collection('transactions').create(body: {
        'title': 'Pembayaran Premium - ${widget.planName ?? 'Langganan'}',
        'amount': grossAmount,
        'type': 'expense',
        'category': 'Premium / Subscription',
        'date': DateTime.now().toIso8601String(),
        'note': 'Order ID: $orderId | Transaction ID: $transactionId',
        'user': pb.authStore.model?.id,
      });

      debugPrint('[PaymentWebview] Premium transaction saved');
    } catch (e) {
      debugPrint('[PaymentWebview] Error saving premium transaction: $e');
    }
  }

  Future<void> _handleSuccess() async {
    if (_hasHandledResult) return;
    _hasHandledResult = true;

    await Future.delayed(const Duration(seconds: 1));

    final midtransData = <String, dynamic>{
      'order_id': '',
      'transaction_id': '',
      'transaction_status': 'settlement',
      'payment_type': 'bank_transfer',
      'gross_amount': '0',
      'currency': 'IDR',
    };

    await _saveMidtransLog(midtransData);
    await _savePremiumTransaction(midtransData);

    if (mounted) {
      context.read<UsageBloc>().add(const UsageUpgradeToPremium());

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.pop(context, PaymentStatus.success);
      }
    }
  }

  void _handlePending() {
    if (_hasHandledResult) return;
    _hasHandledResult = true;

    if (mounted) {
      Navigator.pop(context, PaymentStatus.pending);
    }
  }

  void _handleFailed() {
    if (_hasHandledResult) return;
    _hasHandledResult = true;

    if (mounted) {
      Navigator.pop(context, PaymentStatus.failed);
    }
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
