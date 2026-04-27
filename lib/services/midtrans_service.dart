import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../database/pb_helper.dart';
import '../models/payment_model.dart';

class MidtransService {
  PocketBase? _pb;

  String get _pbBaseUrl => PbHelper().pb.baseURL;
  String get pbBaseUrl => _pbBaseUrl; // Public for debug

  PocketBase get _pocketBase {
    _pb ??= PbHelper().pb;
    return _pb!;
  }

  bool get isConfigured => _pbBaseUrl.isNotEmpty;

  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9000) + 1000;
    return 'PREMIUM-$timestamp-$random';
  }

  Future<String> createSnapToken({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'PocketBase belum dikonfigurasi. Pastikan server berjalan!',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[Midtrans] Creating snap token for order: $orderId, amount: $amount',
      );
    }

    try {
      final response = await _pocketBase.send(
        '/api/create-snap-token',
        method: 'POST',
        body: {
          'order_id': orderId,
          'amount': amount.toInt(),
          'customer_name': customerName,
          'customer_email': customerEmail,
        },
      );

      if (kDebugMode) {
        debugPrint('[Midtrans] Response: $response');
      }

      final token = response['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak valid dari server');
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Midtrans] Error: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('403')) {
        throw Exception('Autentikasi gagal. Hubungi administrator!');
      }
      if (e.toString().contains('500')) {
        throw Exception(
          'Server payment belum dikonfigurasi. Hubungi administrator!',
        );
      }
      rethrow;
    }
  }

  String getSnapUrl(String snapToken) {
    final snapUrl = _pbBaseUrl.contains('sandbox') || _pbBaseUrl.isEmpty
        ? 'https://app.sandbox.midtrans.com/snap/v2/vtweb'
        : 'https://app.midtrans.com/snap/v2/vtweb';
    return '$snapUrl/$snapToken';
  }

  static const Map<PremiumPlan, int> planPrices = {
    PremiumPlan.monthly: 49000,
    PremiumPlan.yearly: 249000,
  };

  static const Map<PremiumPlan, String> planNames = {
    PremiumPlan.monthly: 'Premium Bulanan',
    PremiumPlan.yearly: 'Premium Tahunan',
  };
}
