import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/payment_model.dart';
import '../../../services/pb_client.dart';

class MidtransService {
  PocketBase get _pocketBase => PbClient.instance;

  String get _pbBaseUrl => _pocketBase.baseURL;
  String get pbBaseUrl => _pbBaseUrl;

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
        'Server tidak terhubung. Pastikan PocketBase berjalan!',
      );
    }

    if (kDebugMode) {
      debugPrint('[Midtrans] Auth valid: ${_pocketBase.authStore.isValid}');
      debugPrint('[Midtrans] Creating snap token for order: $orderId, amount: $amount');
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
          'is_production': AppConfig.isProduction,
        },
      );

      if (kDebugMode) {
        debugPrint('[Midtrans] Response: $response');
      }

      final token = response['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Token pembayaran tidak valid dari server');
      }

      return token;
    } on ClientException catch (e) {
      if (kDebugMode) debugPrint('[Midtrans] ClientException: $e');
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw Exception('Sesi login habis. Silakan login ulang.');
      }
      if (e.statusCode == 502) {
        final response = e.response;
        if (response['midtrans_json'] != null) {
          final messages = response['midtrans_json']['error_messages'];
          if (messages is List && messages.isNotEmpty) {
            throw Exception('Midtrans Error: ${messages.first}');
          }
        }
        throw Exception('Gagal terhubung ke Midtrans. Periksa konfigurasi server.');
      }
      if (e.statusCode == 500) {
        throw Exception(
          'Server payment error. Midtrans mungkin belum dikonfigurasi.',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[Midtrans] Error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        );
      }
      rethrow;
    }
  }

  String getSnapUrl(String snapToken) {
    final snapUrl = AppConfig.isProduction
        ? 'https://app.midtrans.com/snap/v2/vtweb'
        : 'https://app.sandbox.midtrans.com/snap/v2/vtweb';
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
