// === FILE: lib/services/ai_service.dart ===
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_genai/google_genai.dart';

import '../models/transaction_model.dart';

class AiService {
  static AiService? _instance;
  late GenerativeModel _model;
  ChatSession? _chat;

  factory AiService() {
    _instance ??= AiService._internal();
    return _instance!;
  }

  AiService._internal();

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

  Future<void> initialize() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: _systemPrompt,
    );
    _chat = _model.startChat();
  }

  Future<AiResponse> sendMessage(String message, DateTime currentDate) async {
    try {
      if (_chat == null) {
        await initialize();
      }

      final messageWithContext =
          '$message\n[Tanggal hari ini: ${currentDate.toIso8601String().split('T')[0]}]';

      final response = await _chat!.sendMessage(
        Content.text(messageWithContext),
      );

      final responseText = response.text ?? '';

      return _parseResponse(responseText);
    } catch (e) {
      return AiResponse(
        action: AiAction.chat,
        message: 'Maaf, ada gangguan koneksi AI. Coba lagi ya! 😅',
      );
    }
  }

  Future<AiResponse> parseOcrText(String ocrText, DateTime currentDate) async {
    try {
      if (_chat == null) {
        await initialize();
      }

      final prompt =
          'Tolong analisis struk/nota berikut dan ekstrak informasi transaksi:\n\n'
          '$ocrText\n\n'
          'Tentukan: total nominal (dalam angka polos tanpa titik/koma), kategori yang paling tepat dari list ini: Makanan, Transportasi, Belanja, Hiburan, Kesehatan, Pendidikan, Tagihan, Lainnya, Gaji, Bonus, Usaha, Investasi, Hadiah, dan catatan singkat. Balas dalam format JSON saja.';

      final response = await _chat!.sendMessage(Content.text(prompt));

      final responseText = response.text ?? '';

      return _parseResponse(responseText);
    } catch (e) {
      return AiResponse(
        action: AiAction.chat,
        message: 'Gagal memproses struk. Coba lagi ya! 😅',
      );
    }
  }

  AiResponse _parseResponse(String responseText) {
    try {
      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final action = json['action'] as String;

      if (action == 'add_transaction') {
        final data = json['data'] as Map<String, dynamic>;
        final transaction = TransactionModel(
          title: data['category'] as String,
          amount: (data['amount'] as num).toDouble(),
          type: data['type'] as String,
          category: data['category'] as String,
          date: DateTime.parse(data['date'] as String),
          note: data['note'] as String? ?? '',
        );
        return AiResponse(
          action: AiAction.addTransaction,
          transaction: transaction,
          message: json['message'] as String,
        );
      } else {
        return AiResponse(
          action: AiAction.chat,
          message: json['message'] as String,
        );
      }
    } catch (e) {
      return AiResponse(
        action: AiAction.chat,
        message: responseText,
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