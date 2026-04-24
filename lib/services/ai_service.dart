// === FILE: lib/services/ai_service.dart ===
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/transaction_model.dart';

class AiService {
  static AiService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;
  String? _lastError;

  factory AiService() {
    _instance ??= AiService._internal();
    return _instance!;
  }
  AiService._internal();

  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  static const String _systemPrompt = '''
Kamu adalah asisten keuangan pribadi yang cerdas dalam aplikasi Personal Finance.
Tugasmu adalah membantu pengguna mencatat transaksi keuangan dari percakapan natural.

KEMAMPUANMU:
1. Ekstrak informasi transaksi dari teks natural bahasa Indonesia/Inggris
2. Tentukan apakah itu pemasukan (income) atau pengeluaran (expense)
3. Ekstrak nominal, kategori, dan catatan
4. Berikan saran keuangan sederhana jika diminta

KATEGORI YANG TERSEDIA:
- Pengeluaran: Makanan, Transportasi, Belanja, Hiburan, Kesehatan, Pendidikan, Tagihan, Lainnya
- Pemasukan: Gaji, Bonus, Usaha, Investasi, Hadiah, Lainnya

JIKA USER INGIN CATAT TRANSAKSI, balas dalam format JSON TEPAT ini:
{
  "action": "add_transaction",
  "data": {
    "type": "expense" atau "income",
    "amount": angka (tanpa titik/koma),
    "category": "nama kategori",
    "note": "deskripsi singkat",
    "date": "YYYY-MM-DD"
  },
  "message": "pesan konfirmasi dalam Bahasa Indonesia"
}

JIKA HANYA PERCAKAPAN BIASA atau PERTANYAAN, balas dengan:
{
  "action": "chat",
  "message": "respons dalam Bahasa Indonesia yang ramah dan helpful"
}

CONTOH:
User: "tadi makan siang 35rb"
Response: {"action":"add_transaction","data":{"type":"expense","amount":35000,"category":"Makanan","note":"makan siang","date":"2026-04-24"},"message":"Oke! Pengeluaran makan siang Rp 35.000 sudah dicatat 🍽️"}

User: "gajian 5 juta"
Response: {"action":"add_transaction","data":{"type":"income","amount":5000000,"category":"Gaji","note":"gaji bulanan","date":"2026-04-24"},"message":"Mantap! Pemasukan gaji Rp 5.000.000 berhasil dicatat 💰"}

User: "berapa pengeluaran aku bulan ini?"
Response: {"action":"chat","message":"Untuk melihat total pengeluaran, kamu bisa cek tab Laporan ya!"}

PENTING: Selalu balas dalam format JSON valid. Jangan tambahkan teks di luar JSON.
''';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (kDebugMode) {
        if (apiKey.isEmpty) {
          debugPrint('[AiService] ERROR: GEMINI_API_KEY kosong!');
        } else {
          debugPrint('[AiService] API Key loaded: ${apiKey.substring(0, 8)}...');
        }
      }

      if (apiKey.isEmpty) {
        _lastError = 'api_key_empty';
        return false;
      }

      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 512,
          responseMimeType: 'text/plain',
        ),
      );

      _chat = _model!.startChat(
        history: [
          Content.system(_systemPrompt),
        ],
      );

      _isInitialized = true;
      _lastError = null;
      debugPrint('[AiService] Initialized successfully!');
      return true;

    } catch (e) {
      debugPrint('[AiService] Init error: $e');
      _lastError = e.toString();
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> reinitialize() async {
    _isInitialized = false;
    _model = null;
    _chat = null;
    _lastError = null;
    return await initialize();
  }

  Future<AiResponse> sendMessage(String message, DateTime currentDate) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        return _buildErrorResponse(_lastError);
      }
    }

    try {
      final messageWithContext =
          '$message\n[Tanggal hari ini: ${currentDate.toIso8601String().split('T')[0]}]';

      final response = await _chat!.sendMessage(
        Content.text(messageWithContext),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Request timeout', const Duration(seconds: 20)),
      );

      final responseText = response.text ?? '';
      
      if (kDebugMode) {
        debugPrint('[AiService] Raw response: $responseText');
      }
      
      if (responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return _parseResponse(responseText);

    } on TimeoutException {
      return AiResponse(
        action: AiAction.chat,
        message: 'Koneksi AI timeout. Pastikan internet aktif dan coba lagi! ⏱️',
      );
    } on Exception catch (e) {
      debugPrint('[AiService] sendMessage error: $e');
      
      final errorStr = e.toString().toLowerCase();
      String errorMsg = 'Maaf, AI sedang tidak tersedia. Coba lagi ya! 😅';
      
      if (errorStr.contains('api_key') || errorStr.contains('api key') || errorStr.contains('invalid')) {
        errorMsg = 'API Key tidak valid. Cek konfigurasi .env kamu ya! 🔑';
        _isInitialized = false;
      } else if (errorStr.contains('quota') || errorStr.contains('429') || errorStr.contains('rate')) {
        errorMsg = 'Batas penggunaan AI tercapai. Coba lagi dalam beberapa menit! 📊';
      } else if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMsg = 'Tidak ada koneksi internet. Pastikan WiFi/data aktif! 📶';
      } else if (errorStr.contains('503') || errorStr.contains('unavailable')) {
        errorMsg = 'Server AI sedang sibuk. Coba lagi sebentar ya! 🔄';
      }
      
      return AiResponse(action: AiAction.chat, message: errorMsg);
    }
  }

  AiResponse _buildErrorResponse(String? errorType) {
    switch (errorType) {
      case 'api_key_empty':
        return AiResponse(
          action: AiAction.chat,
          message: '⚠️ API Key Gemini belum dikonfigurasi.\n\n'
                   'Cara mendapatkan API Key gratis:\n'
                   '1. Buka aistudio.google.com\n'
                   '2. Klik "Get API Key"\n'
                   '3. Buat project baru\n'
                   '4. Copy API key\n'
                   '5. Paste di file .env:\n'
                   '   GEMINI_API_KEY=key_kamu_disini\n\n'
                   'Setelah itu restart aplikasi ya! 🔄',
        );
      default:
        return AiResponse(
          action: AiAction.chat,
          message: 'Gagal menginisialisasi AI. Error: $_lastError\n\nCoba restart aplikasi! 🔄',
        );
    }
  }

  AiResponse _parseResponse(String responseText) {
    try {
      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```dart', '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final action = json['action'] as String? ?? 'chat';

      if (action == 'add_transaction') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null) throw Exception('Missing data field');

        double amount = 0;
        final rawAmount = data['amount'];
        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          amount = double.tryParse(rawAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        }

        final transaction = TransactionModel(
          title: data['category'] as String? ?? 'Lainnya',
          amount: amount,
          type: data['type'] as String? ?? 'expense',
          category: data['category'] as String? ?? 'Lainnya',
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
          note: data['note'] as String? ?? '',
        );

        return AiResponse(
          action: AiAction.addTransaction,
          transaction: transaction,
          message: json['message'] as String? ?? 'Transaksi siap disimpan!',
        );
      } else {
        return AiResponse(
          action: AiAction.chat,
          message: json['message'] as String? ?? responseText,
        );
      }
    } catch (e) {
      debugPrint('[AiService] Parse error: $e\nRaw: $responseText');
      return AiResponse(
        action: AiAction.chat,
        message: responseText.length > 500 
          ? '${responseText.substring(0, 500)}...' 
          : responseText,
      );
    }
  }
}

enum AiAction { chat, addTransaction }

class AiResponse {
  final AiAction action;
  final String message;
  final TransactionModel? transaction;

  AiResponse({
    required this.action,
    required this.message,
    this.transaction,
  });
}