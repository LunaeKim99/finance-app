import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/datasources/smart_db_helper.dart';
import '../../../data/datasources/pb_helper.dart';
import '../../../data/datasources/local/sqlite_helper.dart';

const String _apiToken = AppConfig.groqApiKey;

const List<Map<String, String>> kGroqModelFallbacks = [
  {'model': 'llama-3.1-8b-instant', 'label': 'Llama 3.1 8B'},
  {'model': 'llama3-8b-8192', 'label': 'Llama 3 8B'},
  {'model': 'gemma2-9b-it', 'label': 'Gemma 2 9B'},
  {'model': 'mixtral-8x7b-32768', 'label': 'Mixtral 8x7B'},
  {'model': 'llama-3.3-70b-versatile', 'label': 'Llama 3.3 70B'},
];

class AiService {
  static AiService? _instance;
  bool _isInitialized = false;
  String? _lastError;
  DateTime? _lastRequestTime;

  int _currentModelIndex = 0;
  DateTime? _modelSwitchedAt;

  String get _currentModel => kGroqModelFallbacks[_currentModelIndex]['model']!;
  String get currentModelLabel =>
      kGroqModelFallbacks[_currentModelIndex]['label']!;

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _minRequestInterval = Duration(seconds: 3);

  factory AiService() {
    _instance ??= AiService._internal();
    return _instance!;
  }
  AiService._internal();

  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  static String _buildSystemPrompt(List<String> expenseCategories, List<String> incomeCategories) {
    final expenseStr = expenseCategories.join(', ');
    final incomeStr = incomeCategories.join(', ');
    return '''
Kamu adalah asisten keuangan pribadi yang cerdas dalam aplikasi UWANGKU.
Tugasmu adalah membantu pengguna mencatat transaksi keuangan dari percakapan natural.

BATASAN TOPIK - KAMU HANYA BOLEH MENJAWAB TOPIK KEUANGAN:
✅ Topik yang DIIZINKAN:
- Mencatat transaksi pemasukan dan pengeluaran
- Kategori keuangan ($expenseStr, $incomeStr, dll)
- Budgeting, pengelolaan uang, dan perencanaan keuangan pribadi
- Tabungan, investasi dasar, dan pengelolaan aset
- Laporan, ringkasan, dan analisis keuangan
- Pertanyaan seputar fitur aplikasi UWANGKU yang terkait keuangan

❌ Topik yang DILARANG:
- Politik, agama, suku, ras, dan isu sensitif lainnya
- Kesehatan, medis, penyakit, atau obat-obatan (kecuali biaya pengobatan)
- Teknologi, pemrograman, coding, dan gadget (kecuali biaya pembelian/servis)
- Hiburan, film, musik, game, dan hobi (kecuali biaya terkait)
- Hubungan, percintaan, keluarga, dan curhat personal (kecuali konteks keuangan)
- Resep masakan, tips memasak, atau kuliner (kecuali mencatat pengeluaran makan)
- Olahraga, berita umum, peristiwa terkini, dan sejarah
- Apapun yang tidak berhubungan langsung dengan manajemen keuangan pribadi

JIKA USER BERTANYA DI LUAR TOPIK KEUANGAN, balas HANYA dengan format JSON ini:
{
  "action": "chat",
  "message": "Maaf, aku hanya bisa membantu pertanyaan seputar keuangan pribadi dan aplikasi UWANGKU. Ada transaksi yang mau dicatat? 😊"
}

JANGAN PERNAH menjawab pertanyaan di luar topik keuangan dalam keadaan apapun. Tetaplah menjadi asisten keuangan yang disiplin.

KEMAMPUANMU:
1. Ekstrak informasi transaksi dari teks natural bahasa Indonesia/Inggris
2. Tentukan apakah itu pemasukan (income) atau pengeluaran (expense)
3. Ekstrak nominal, kategori, dan catatan
4. Berikan saran keuangan sederhana jika diminta

KATEGORI YANG TERSEDIA:
- Pengeluaran: $expenseStr
- Pemasukan: $incomeStr

PENTING! DETEKSI MATA UANG:
Jika user menyebut mata uang asing (dolar, dollar, USD, SGD, euro, yen, pound, dll), maka:
- JANGAN konversi nominal ke IDR!
- Simpan nominal dalam mata uang asli yang disebut
- Sertakan field "currency" dengan kode mata uang (USD, SGD, EUR, JPY, GBP, dll)

Contoh deteksi mata uang:
- "500 dolar" → currency: "USD", amount: 500
- "100 SGD" → currency: "SGD", amount: 100
- "makan siang 35rb" → currency: "IDR", amount: 35000
- "gaji 50 euro" → currency: "EUR", amount: 50
- "belanja 200 ribu" → currency: "IDR", amount: 200000
- Jika tidak menyebut satuan mata uang, anggap IDR

JIKA USER INGIN CATAT TRANSAKSI, balas HANYA dalam format JSON ini:
{
  "action": "add_transaction",
  "data": {
    "type": "expense" atau "income",
    "amount": angka bulat tanpa titik atau koma,
    "currency": "kode mata uang (IDR/USD/SGD/EUR/etc)",
    "category": "nama kategori dari list di atas",
    "note": "deskripsi singkat transaksi",
    "date": "YYYY-MM-DD"
  },
  "message": "pesan konfirmasi singkat dalam Bahasa Indonesia dengan emoji, sebutkan mata uang jika bukan IDR"
}

JIKA HANYA PERTANYAAN KEUANGAN ATAU PERCAKAPAN BIASA (TETAPI MASIH DALAM TOPIK KEUANGAN), balas HANYA dalam format JSON ini:
{
  "action": "chat",
  "message": "respons dalam Bahasa Indonesia yang ramah, helpful, dan tetap fokus pada topik keuangan"
}

CONTOH INPUT → OUTPUT:
  Input: "tadi makan siang 35rb" → { "action":"add_transaction","data":{"type":"expense","amount":35000,"currency":"IDR","category":"Makanan","note":"makan siang","date":"2026-04-25"},"message":"Oke! Pengeluaran makan siang Rp 35.000 dicatat 🍽️" }
  Input: "gajian 5 juta" → { "action":"add_transaction","data":{"type":"income","amount":5000000,"currency":"IDR","category":"Gaji","note":"gaji bulanan","date":"2026-04-25"},"message":"Mantap! Pemasukan gaji Rp 5.000.000 dicatat 💰" }
  Input: "gaji 500 dolar" → { "action":"add_transaction","data":{"type":"income","amount":500,"currency":"USD","category":"Gaji","note":"gaji","date":"2026-04-25"},"message":"Oke! Pemasukan \$500 USD dicatat. Nilai dalam IDR: Rp 8.125.000 💰" }
  Input: "berapa pengeluaran bulan ini?" → { "action":"chat","message":"Untuk melihat total pengeluaran, buka tab Laporan ya! 📊" }
  Input: "siapa presiden indonesia?" → { "action":"chat","message":"Maaf, aku hanya bisa membantu pertanyaan seputar keuangan pribadi dan aplikasi UWANGKU. Ada transaksi yang mau dicatat? 😊" }

ATURAN PENTING:
- Selalu balas HANYA dengan JSON valid, tidak ada teks di luar JSON
- Jangan tambahkan markdown, komentar, atau penjelasan apapun
- Nominal selalu berupa angka integer, bukan string
- Tanggal selalu format YYYY-MM-DD
- Jika ragu antara income/expense, tanya ke user dalam format chat JSON
''';
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (kDebugMode) {
      if (!AppConfig.isGroqConfigured) {
        debugPrint('[AiService] ERROR: GROQ_API_KEY tidak ditemukan! Use --dart-define=GROQ_API_KEY=your_key');
      } else {
        debugPrint('[AiService] Groq API Key: ${_apiToken.substring(0, 8)}...');
      }
    }

    if (!AppConfig.isGroqConfigured) {
      _lastError = 'token_empty';
      return false;
    }

    _isInitialized = true;
    _lastError = null;
    debugPrint('[AiService] Initialized successfully! Model: $_currentModel');
    return true;
  }

  void _tryResetModel() {
    if (_currentModelIndex > 0 && _modelSwitchedAt != null) {
      final elapsed = DateTime.now().difference(_modelSwitchedAt!);
      if (elapsed.inMinutes >= 5) {
        _currentModelIndex = 0;
        _modelSwitchedAt = null;
        debugPrint('[AiService] Model direset ke $_currentModel');
      }
    }
  }

  Future<http.Response> _callWithFallback(Map<String, dynamic> body) async {
    final startIndex = _currentModelIndex;

    for (int i = startIndex; i < kGroqModelFallbacks.length; i++) {
      final model = kGroqModelFallbacks[i]['model']!;
      final label = kGroqModelFallbacks[i]['label']!;
      body['model'] = model;

      debugPrint('[AiService] Mencoba model: $label ($model)');

      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer $_apiToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 429 || response.statusCode == 503) {
          debugPrint(
              '[AiService] $label kena limit (${response.statusCode}), switch...');
          if (i + 1 < kGroqModelFallbacks.length) {
            _currentModelIndex = i + 1;
            _modelSwitchedAt = DateTime.now();
          }
          continue;
        }

        if (i != startIndex) {
          debugPrint('[AiService] Berhasil dengan fallback: $label');
        }
        return response;

      } on TimeoutException {
        debugPrint('[AiService] $label timeout, mencoba model berikutnya...');
        continue;
      }
    }

    _currentModelIndex = 0;
    _modelSwitchedAt = null;
    throw Exception('semua_model_gagal');
  }

  Future<bool> reinitialize() async {
    _isInitialized = false;
    _lastError = null;
    return await initialize();
  }

  bool _isFinanceRelated(String message) {
    final lowMessage = message.toLowerCase();
    
    // Daftar kata kunci yang jelas-jelas bukan keuangan (off-topic)
    final offTopicKeywords = [
      'siapa presiden', 'cara masak', 'resep', 'tutorial coding', 'belajar bahasa',
      'film terbaik', 'lagu favorit', 'politik', 'agama', 'sejarah dunia',
      'cara membuat website', 'coding python', 'java script', 'apa itu quantum',
      'hasil pertandingan', 'skor bola', 'berita terkini',
    ];

    for (final keyword in offTopicKeywords) {
      if (lowMessage.contains(keyword)) return false;
    }

    // Daftar kata kunci yang menandakan ini topik keuangan
    final financeKeywords = [
      'uang', 'rupiah', 'rb', 'juta', 'ribu', 'harga', 'bayar', 'beli', 'jual', 
      'gaji', 'tabungan', 'investasi', 'catat', 'pengeluaran', 'pemasukan', 
      'budget', 'hemat', 'biaya', 'saldo', 'transaksi', 'tabung', 'kredit', 'debet',
    ];

    for (final keyword in financeKeywords) {
      if (lowMessage.contains(keyword)) return true;
    }

    // Jika tidak yakin, biarkan AI yang memutuskan lewat system prompt
    return true;
  }

  Future<AiResponse> sendMessage(String message, DateTime currentDate) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return _buildErrorResponse(_lastError);
    }

    // Pre-filter: Cek apakah topik berkaitan dengan keuangan
    if (!_isFinanceRelated(message)) {
      return AiResponse(
        action: AiAction.chat,
        message: 'Maaf, aku hanya bisa membantu pertanyaan seputar keuangan pribadi dan aplikasi UWANGKU. Ada transaksi yang mau dicatat? 😊',
      );
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

    // Load user categories for dynamic prompt
    List<String> expenseCats = ['Makanan', 'Transportasi', 'Belanja', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Tagihan', 'Lainnya'];
    List<String> incomeCats = ['Gaji', 'Bonus', 'Usaha', 'Investasi', 'Hadiah', 'Lainnya'];
    try {
      final allCats = await SmartDbHelper(remote: PbHelper(), local: SqliteHelper()).fetchAllCategories();
      if (allCats.isNotEmpty) {
        expenseCats = allCats.where((c) => c.type == 'expense').map((c) => c.name).toList();
        incomeCats = allCats.where((c) => c.type == 'income').map((c) => c.name).toList();
      }
    } catch (_) {}

    try {
      _tryResetModel();

      final requestBody = jsonEncode({
        'model': _currentModel,
        'messages': [
          {
            'role': 'system',
            'content': _buildSystemPrompt(expenseCats, incomeCats),
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
        debugPrint('[AiService] Sending to Groq API... Model: $currentModelLabel');
      }

      final bodyMap = jsonDecode(requestBody) as Map<String, dynamic>;
      final response = await _callWithFallback(bodyMap);

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

        case 401:
          _isInitialized = false;
          return AiResponse(
            action: AiAction.chat,
            message:
                'HF Token tidak valid atau expired. Cek file .env kamu! 🔑',
          );

        case 403:
          return AiResponse(
            action: AiAction.chat,
            message:
                'Akses ditolak. Pastikan token HF punya permission "Read"! 🔒',
          );

        default:
          debugPrint(
              '[AiService] Unexpected status: ${response.statusCode}\n${response.body}');
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
      if (e.toString().contains('semua_model_gagal')) {
        return AiResponse(
          action: AiAction.chat,
          message:
              'Semua model AI sedang tidak tersedia. Coba lagi dalam beberapa menit! 🔄',
        );
      }
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
        message: '⚠️ Groq API Key belum dikonfigurasi!\n\n'
                 'Cara mendapatkan API key gratis:\n'
                 '1. Daftar di console.groq.com\n'
                 '2. Buka API Keys → Create API Key\n'
                 '3. Copy key → build dengan:\n'
                 '   flutter run --dart-define=GROQ_API_KEY=gsk_xxxxxxxx\n\n'
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

        final currency = data['currency'] as String? ?? 'IDR';
        final exchangeRate = currency != 'IDR'
            ? ExchangeRateService.instance.getRate(currency)
            : 1.0;

        final transaction = TransactionModel(
          title: data['category'] as String? ?? 'Lainnya',
          amount: amount,
          type: TransactionType.fromString(data['type'] as String? ?? 'expense'),
          categoryId: data['category'] as String? ?? 'Lainnya',
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
          note: data['note'] as String? ?? '',
          currency: currency,
          exchangeRateToIdr: exchangeRate,
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

class AiRecommendationService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _minRequestInterval = Duration(seconds: 3);

  DateTime? _lastRequestTime;
  int _currentModelIndex = 0;
  DateTime? _modelSwitchedAt;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String get _apiKey => AppConfig.groqApiKey;

  Future<String> _sendToGroq(String systemPrompt, String userPrompt) async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw Exception('API key belum dikonfigurasi. Gunakan --dart-define=GROQ_API_KEY=your_key');
    }

    if (_currentModelIndex > 0 && _modelSwitchedAt != null) {
      if (DateTime.now().difference(_modelSwitchedAt!).inMinutes >= 5) {
        _currentModelIndex = 0;
        _modelSwitchedAt = null;
      }
    }

    final bodyBase = {
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    };

    for (int i = _currentModelIndex; i < kGroqModelFallbacks.length; i++) {
      final model = kGroqModelFallbacks[i]['model']!;
      final label = kGroqModelFallbacks[i]['label']!;
      final body = {...bodyBase, 'model': model};

      debugPrint('[AiRecommendation] Mencoba: $label');

      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 429 || response.statusCode == 503) {
          if (i + 1 < kGroqModelFallbacks.length) {
            _currentModelIndex = i + 1;
            _modelSwitchedAt = DateTime.now();
          }
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception('AI error: ${response.statusCode}');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isEmpty) throw Exception('Response kosong');

        return choices[0]['message']['content'] as String;

      } on TimeoutException {
        continue;
      }
    }

    _currentModelIndex = 0;
    _modelSwitchedAt = null;
    throw Exception('Semua model AI tidak tersedia saat ini');
  }

  Future<String> generateWeeklySummary(List<TransactionModel> transactions) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklyTx = transactions.where((t) => t.date.isAfter(weekAgo)).toList();
    if (weeklyTx.isEmpty) {
      return 'Belum ada transaksi minggu ini. Catat transaksi pertamamu! 📝';
    }

    final buffer = StringBuffer();
    for (final tx in weeklyTx) {
      final dateStr = DateFormat('dd/MM').format(tx.date);
      final amountStr = _currencyFormat.format(tx.amount);
      buffer.writeln('$dateStr | ${tx.categoryName ?? tx.categoryId} | ${tx.type} | $amountStr');
    }

    const systemPrompt = '''Kamu adalah asisten keuangan pribadi yang ramah dan berbahasa Indonesia santai.
Buat ringkasan keuangan mingguan berdasarkan data transaksi berikut.
Tulis dalam 2-3 paragraf pendek, gunakan bahasa yang mudah dipahami,
sertakan total pengeluaran, kategori terbesar, dan 1 kalimat motivasi di akhir.
Fokus hanya pada data keuangan yang diberikan. Jangan bahas topik di luar keuangan pribadi.''';

    final userPrompt = 'Data transaksi 7 hari terakhir:\n${buffer.toString()}';

    try {
      return await _sendToGroq(systemPrompt, userPrompt);
    } catch (e) {
      return 'Gagal membuat ringkasan: $e';
    }
  }

  Future<String> generateBudgetRecommendation({
    required Map<String, double> categoryTotals,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final buffer = StringBuffer();
    for (final entry in categoryTotals.entries) {
      buffer.writeln('${entry.key}: ${_currencyFormat.format(entry.value)}');
    }

    const systemPrompt = '''Kamu adalah financial coach yang berbahasa Indonesia. Berikan tepat 3 saran
keuangan yang konkret dan spesifik berdasarkan data bulan ini.
Format output: daftar bernomor 1-3, setiap saran maksimal 2 kalimat.
Saran harus realistis dan menyebutkan nominal jika relevan.
Fokus hanya pada data keuangan yang diberikan. Jangan bahas topik di luar keuangan pribadi.''';

    final userPrompt = '''Data keuangan bulan ini:
Total Pemasukan: ${_currencyFormat.format(totalIncome)}
Total Pengeluaran: ${_currencyFormat.format(totalExpense)}
Pengeluaran per Kategori:
${buffer.toString()}''';

    try {
      return await _sendToGroq(systemPrompt, userPrompt);
    } catch (e) {
      return 'Gagal membuat saran: $e';
    }
  }

  Future<String> generateMonthlySummary(
    List<TransactionModel> transactions,
    String monthName,
  ) async {
    if (transactions.isEmpty) {
      return 'Tidak ada transaksi pada $monthName.';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryMap = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categoryMap[tx.categoryName ?? tx.categoryId] = (categoryMap[tx.categoryName ?? tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryText = sortedCategories
        .take(5)
        .map((e) =>
            '- ${e.key}: ${_currencyFormat.format(e.value)}')
        .join('\n');

    final systemPrompt = '''
Kamu adalah asisten keuangan pribadi yang ramah dan berbicara Bahasa Indonesia.
Buat ringkasan keuangan bulanan dalam 3-4 paragraf singkat.

Gunakan format markdown dengan bullet points. Singkat, jelas, dan actionable.
Selalu gunakan emoji di awal setiap bullet point.
Fokus hanya pada data keuangan yang diberikan. Jangan bahas topik di luar keuangan pribadi.''';

    final userPrompt = '''
Data keuangan bulan $monthName:
- Total Pemasukan: ${_currencyFormat.format(totalIncome)}
- Total Pengeluaran: ${_currencyFormat.format(totalExpense)}
- Saldo Bersih: ${_currencyFormat.format(totalIncome - totalExpense)}
- Jumlah Transaksi: ${transactions.length}
- Kategori Pengeluaran Terbesar:
$categoryText

Sertakan:
1. Evaluasi keuangan bulan ini (positif/negatif)
2. Kategori yang perlu diperhatikan
3. Saran praktis untuk bulan depan
4. Motivasi singkat''';

    try {
      return await _sendToGroq(systemPrompt, userPrompt);
    } catch (e) {
      return 'Gagal membuat ringkasan: $e';
    }
  }
}
