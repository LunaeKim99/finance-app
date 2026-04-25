import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/payment_model.dart';

class MidtransService {
  String? get _serverKey => dotenv.env['MIDTRANS_SERVER_KEY'];
  String? get _clientKey => dotenv.env['MIDTRANS_CLIENT_KEY'];
  String? get _baseUrl => dotenv.env['MIDTRANS_BASE_URL'];

  bool get isConfigured => 
      _serverKey != null && 
      _serverKey!.isNotEmpty && 
      _baseUrl != null && 
      _baseUrl!.isNotEmpty;

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
      throw Exception('Midtrans belum dikonfigurasi. Cek file .env!');
    }

    final credentials = base64Encode(utf8.encode('$_serverKey:'));

    if (kDebugMode) {
      debugPrint('[Midtrans] Creating snap token for order: $orderId, amount: $amount');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': amount.toInt(),
          },
          'customer_details': {
            'first_name': customerName,
            'email': customerEmail,
          },
          'item_details': [
            {
              'id': 'PREMIUM_PLAN',
              'price': amount.toInt(),
              'quantity': 1,
              'name': 'Finance App Premium',
            }
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('[Midtrans] Response status: ${response.statusCode}');
        debugPrint('[Midtrans] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        
        if (token == null || token.isEmpty) {
          throw Exception('Token tidak valid dari Midtrans');
        }
        
        return token;
      } else if (response.statusCode == 401) {
        throw Exception('Server key tidak valid. Cek MIDTRANS_SERVER_KEY di .env');
      } else if (response.statusCode == 402) {
        throw Exception('Pembayaran belum selesai atau tidak valid');
      } else {
        throw Exception('Gagal membuat token: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Midtrans] Error: $e');
      }
      rethrow;
    }
  }

  String getSnapUrl(String snapToken) {
    final baseHttpUrl = _baseUrl ?? '';
    final baseSnapUrl = baseHttpUrl.contains('sandbox') 
        ? 'https://app.sandbox.midtrans.com/snap/v2/vtweb'
        : 'https://app.midtrans.com/snap/v2/vtweb';
    return '$baseSnapUrl/$snapToken';
  }

  static const Map<PremiumPlan, int> planPrices = {
    PremiumPlan.monthly: 29000,
    PremiumPlan.lifetime: 99000,
  };

  static const Map<PremiumPlan, String> planNames = {
    PremiumPlan.monthly: 'Premium Bulanan',
    PremiumPlan.lifetime: 'Premium Seumur Hidup',
  };
}