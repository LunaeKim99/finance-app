import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/receipt_scan_result.dart';
import 'ocr_service.dart';

class ReceiptScanService {
  static const String _model = 'llama-3.1-8b-instant';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _minRequestInterval = Duration(seconds: 3);

  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();

  DateTime? _lastRequestTime;

  Future<File?> pickImage({bool fromCamera = true}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<ReceiptScanResult> scanReceipt(File imageFile) async {
    final ocrResult = await _ocrService.extractText(imageFile.path);

    if (!ocrResult.isSuccess || ocrResult.text.trim().isEmpty) {
      throw Exception(
        'Tidak dapat membaca teks dari gambar.\n'
        'Pastikan foto struk cukup terang dan tulisan terlihat jelas.',
      );
    }

    if (ocrResult.engine == OcrEngine.tesseract) {
      return _parseOfflineResult(ocrResult.text);
    }

    return await _parseWithGroq(ocrResult.text);
  }

  ReceiptScanResult _parseOfflineResult(String rawText) {
    final numberRegex = RegExp(r'\d{3,}(?:[.,]\d{3})*');
    final matches = numberRegex.allMatches(rawText);

    double total = 0;
    for (final match in matches) {
      final numStr = match.group(0)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      final value = double.tryParse(numStr) ?? 0;
      if (value > total) total = value;
    }

    return ReceiptScanResult(
      merchant: 'Tidak diketahui (mode offline)',
      date: DateTime.now(),
      total: total,
      items: [],
      currency: 'IDR',
      usedOfflineMode: true,
    );
  }

  Future<ReceiptScanResult> _parseWithGroq(String rawText) async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key belum dikonfigurasi. Cek file .env!');
    }

    const systemPrompt = '''Kamu adalah asisten keuangan. Analisis teks struk belanja berikut dan ekstrak
informasi dalam format JSON yang valid. Jangan tambahkan teks apapun di luar JSON.
Format output:
{
"merchant": "nama toko atau null",
"date": "YYYY-MM-DD atau null",
"total": 0,
"currency": "IDR",
"items": [
{
"name": "nama item",
"price": 0,
"category": "Makanan|Minuman|Kebersihan|Elektronik|Pakaian|Lainnya"
}
] }''';

    final userPrompt = 'Teks struk:\n$rawText';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.1,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Groq API error: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memproses struk. Coba lagi ya! (Error: ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw Exception('响应 kosong. Coba lagi!');
    }

    final content = choices[0]['message']['content'] as String;
    final jsonText = _extractJson(content);

    return _parseReceiptJson(jsonText);
  }

  String _extractJson(String text) {
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('格式无效');
    }
    return cleaned.substring(jsonStart, jsonEnd + 1);
  }

  ReceiptScanResult _parseReceiptJson(String jsonText) {
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      final itemsList = (json['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      double total = 0;
      final rawTotal = json['total'];
      if (rawTotal is num) {
        total = rawTotal.toDouble();
      } else if (rawTotal is String) {
        total = double.tryParse(rawTotal.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }

      DateTime? date;
      if (json['date'] != null && json['date'] != 'null') {
        date = DateTime.tryParse(json['date'] as String);
      }

      return ReceiptScanResult(
        merchant: json['merchant'] as String? ?? '',
        date: date,
        total: total,
        currency: json['currency'] as String? ?? 'IDR',
        items: itemsList,
        usedOfflineMode: false,
      );
    } catch (e) {
      debugPrint('Parse error: $e');
      throw Exception('Gagal解析数据. Coba lagi dengan foto yang lebih jelas!');
    }
  }

  void dispose() {}
}