// === FILE: lib/services/ai_service.dart ===
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class AiService {
  static AiService? _instance;
  bool _isInitialized = false;
  String _apiToken = '';
  String? _lastError;
  DateTime? _lastRequestTime;

  static const String _model = 'mistralai/Mistral-7B-Instruct-v0.3';
  static const String _baseUrl =
      'https://api-inference.huggingface.co/models/$_model/v1/chat/completions';
  static const Duration _minRequestInterval = Duration(seconds: 3);

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

JIKA USER INGIN CATAT TRANSAKSI, balas HANYA dalam format JSON ini:
{
  "action": "add_transaction",
  "data": {
    "type": "expense" atau "income",
    "amount": angka bulat tanpa titik atau koma,
    "category": "nama kategori dari list di atas",
    "note": "deskripsi singkat transaksi",
    "date": "YYYY-MM-DD"
  },
  "message": "pesan konfirmasi singkat dalam Bahasa Indonesia dengan emoji"
}

JIKA HANYA PERTANYAAN ATAU PERCAKAPAN BIASA, balas HANYA dalam format JSON ini:
{
  "action": "chat",
  "message": "respons dalam Bahasa Indonesia yang ramah dan helpful"
}

CONTOH INPUT → OUTPUT:

Input: "tadi makan siang 35rb"
Output: {"action":"add_transaction","data":{"type":"expense","amount":35000,"category":"Makanan","note":"makan siang","date":"2026-04-25"},"message":"Oke! Pengeluaran makan siang Rp 35.000 dicatat 🍽️"}

Input: "gajian 5 juta"
Output: {"action":"add_transaction","data":{"type":"income","amount":5000000,"category":"Gaji","note":"gaji bulanan","date":"2026-04-25"},"message":"Mantap! Pemasukan gaji Rp 5.000.000 dicatat 💰"}

Input: "beli martabak habisnya 55 ribu"
Output: {"action":"add_transaction","data":{"type":"expense","amount":55000,"category":"Makanan","note":"beli martabak","date":"2026-04-25"},"message":"Catat! Pengeluaran martabak Rp 55.000 tersimpan 🧆"}

Input: "berapa pengeluaran bulan ini?"
Output: {"action":"chat","message":"Untuk melihat total pengeluaran, buka tab Laporan ya! 📊"}

ATURAN PENTING:
- Selalu balas HANYA dengan JSON valid, tidak ada teks di luar JSON
- Jangan tambahkan markdown, komentar, atau penjelasan apapun
- Nominal selalu berupa angka integer, bukan string
- Tanggal selalu format YYYY-MM-DD
- Jika ragu antara income/expense, tanya ke user dalam format chat JSON
''';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _apiToken = dotenv.env['HF_TOKEN'] ?? '';

    if (kDebugMode) {
      if (_apiToken.isEmpty) {
        debugPrint('[AiService] ERROR: HF_TOKEN tidak ditemukan di .env!');
      } else {
        debugPrint('[AiService] HF Token: ${_apiToken.substring(0, 8)}...');
      }
    }

    if (_apiToken.isEmpty) {
      _lastError = 'token_empty';
      return false;
    }

    _isInitialized = true;
    _lastError = null;
    debugPrint('[AiService] Initialized successfully! Model: $_model');
    return true;
  }

  Future<bool> reinitialize() async {
    _isInitialized = false;
    _apiToken = '';
    _lastError = null;
    return await initialize();
  }

  Future<AiResponse> sendMessage(String message, DateTime currentDate) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return _buildErrorResponse(_lastError);
    }

    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final remaining = (_minRequestInterval - elapsed).inSeconds + 1;
        return AiResponse(
          action: AiAction.chat,
          message: 'Tunggu $remaining detik sebelum kirim lagi ya! ⏳',
        );
      }
    }
    _lastRequestTime = DateTime.now();

    final dateStr = currentDate.toIso8601String().split('T')[0];

    try {
      final requestBody = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': '$message\n[Tanggal hari ini: $dateStr]',
          },
        ],
        'max_tokens': 256,
        'temperature': 0.2,
        'stream': false,
      });

      if (kDebugMode) {
        debugPrint('[AiService] Sending to HF API...');
      }

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('HF API timeout'),
          );

      if (kDebugMode) {
        debugPrint('[AiService] Status: ${response.statusCode}');
        debugPrint('[AiService] Body: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>;
          if (choices.isEmpty) {
            throw Exception('Empty choices from API');
          }
          final text = choices[0]['message']['content'] as String;
          return _parseResponse(text.trim());

        case 503:
          return AiResponse(
            action: AiAction.chat,
            message: 'Model AI sedang loading, tunggu 20-30 detik lalu coba lagi! ⏳\n\n'
                     '(Ini normal terjadi jika model belum digunakan beberapa waktu)',
          );

        case 429:
          return AiResponse(
            action: AiAction.chat,
            message: 'Terlalu banyak request. Tunggu 1 menit lalu coba lagi! 🐢',
          );

        case 401:
          _isInitialized = false;
          return AiResponse(
            action: AiAction.chat,
            message: 'HF Token tidak valid atau expired. Cek file .env kamu! 🔑',
          );

        case 403:
          return AiResponse(
            action: AiAction.chat,
            message: 'Akses ditolak. Pastikan token HF punya permission "Read"! 🔒',
          );

        default:
          debugPrint('[AiService] Unexpected status: ${response.statusCode}\n${response.body}');
          return AiResponse(
            action: AiAction.chat,
            message: 'AI error (${response.statusCode}). Coba lagi ya! 😅',
          );
      }
    } on TimeoutException {
      return AiResponse(
        action: AiAction.chat,
        message: 'Request timeout (30s). Pastikan internet stabil dan coba lagi! ⏱️',
      );
    } catch (e) {
      debugPrint('[AiService] Exception: $e');
      return AiResponse(
        action: AiAction.chat,
        message: 'Koneksi bermasalah. Cek internet dan coba lagi! 📶',
      );
    }
  }

  AiResponse _buildErrorResponse(String? errorType) {
    if (errorType == 'token_empty') {
      return AiResponse(
        action: AiAction.chat,
        message: '⚠️ Hugging Face Token belum dikonfigurasi!\n\n'
                 'Cara mendapatkan token gratis:\n'
                 '1. Daftar di huggingface.co\n'
                 '2. Buka Settings → Access Tokens\n'
                 '3. Klik "New token" → role: Read\n'
                 '4. Copy token → paste di file .env:\n'
                 '   HF_TOKEN=hf_xxxxxxxxxxxxx\n\n'
                 'Lalu restart aplikasi! 🔄',
      );
    }
    return AiResponse(
      action: AiAction.chat,
      message: 'Gagal inisialisasi AI. Error: $errorType\nCoba restart app! 🔄',
    );
  }

  AiResponse _parseResponse(String responseText) {
    try {
      if (kDebugMode) {
        debugPrint('[AiService] Parsing: $responseText');
      }

      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        return AiResponse(action: AiAction.chat, message: cleaned);
      }
      cleaned = cleaned.substring(jsonStart, jsonEnd + 1);

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final action = json['action'] as String? ?? 'chat';

      if (action == 'add_transaction') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null) {
          return AiResponse(
            action: AiAction.chat,
            message: json['message'] as String? ?? responseText,
          );
        }

        double amount = 0;
        final rawAmount = data['amount'];
        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          amount = double.tryParse(
                rawAmount.replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0;
        }

        if (amount <= 0) {
          return AiResponse(
            action: AiAction.chat,
            message: 'Nominal transaksi tidak valid. Coba sebutkan lagi dengan jelas ya! 🤔',
          );
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
      debugPrint('[AiService] Parse error: $e\nRaw text: $responseText');
      final truncated = responseText.length > 300
          ? '${responseText.substring(0, 300)}...'
          : responseText;
      return AiResponse(action: AiAction.chat, message: truncated);
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