import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/datasources/remote/ai_service.dart';
import '../../../../data/datasources/remote/voice_service.dart';
import '../../../../data/datasources/remote/ocr_service.dart';
import '../ai_chat_screen.dart';

const String kFinanceSystemPrompt = """
Kamu adalah asisten keuangan personal bernama "FinBot" yang terintegrasi dalam aplikasi keuangan.

ATURAN KETAT yang HARUS kamu ikuti:
1. Kamu HANYA boleh menjawab pertanyaan dan pernyataan yang berkaitan dengan topik keuangan, yaitu:
   - Manajemen keuangan pribadi (budgeting, menabung, investasi)
   - Analisis pengeluaran dan pemasukan
   - Tips hemat dan manajemen hutang/piutang
   - Penjelasan istilah keuangan (saham, obligasi, reksa dana, dll)
   - Laporan dan statistik keuangan user berdasarkan data di aplikasi
   - Saran alokasi keuangan (misal: 50/30/20 rule)
   - Pertanyaan seputar fitur aplikasi keuangan ini

2. Jika user menanyakan hal di LUAR topik keuangan (misalnya: resep masakan, hiburan, teknologi umum, politik, dll), kamu WAJIB menolak dengan sopan dan mengarahkan kembali ke topik keuangan. Gunakan respons seperti:
   "Maaf, saya hanya bisa membantu terkait pertanyaan seputar keuangan. Ada yang bisa saya bantu terkait keuangan Anda hari ini? 😊"

3. Gunakan Bahasa Indonesia yang ramah dan mudah dipahami.
4. Berikan jawaban yang konkret, praktis, dan berbasis data jika memungkinkan.
5. Jangan pernah memberikan saran investasi yang bersifat spekulatif atau menjanjikan keuntungan pasti.
""";

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiService _aiService = AiService();
  final VoiceService _voiceService = VoiceService();
  final OcrService _ocrService = OcrService();
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  String _recognizedWords = '';

  VoidCallback? onVoiceStart;
  VoidCallback? onVoiceStop;
  Future<bool> Function(TransactionModel)? onConfirmTransactionExternal;

  AiChatBloc() : super(const AiChatInitial()) {
    on<AiChatInitialize>(_onInitialize);
    on<AiChatSendMessage>(_onSendMessage);
    on<AiChatClear>(_onClear);
    on<AiChatLoadHistory>(_onLoadHistory);
    on<AiChatRetry>(_onRetry);
    on<AiChatScanImage>(_onScanImage);
    on<AiChatStartVoice>(_onStartVoice);
    on<AiChatStopVoice>(_onStopVoice);
    on<AiChatConfirmTransaction>(_onConfirmTransaction);
    on<AiChatCancelTransaction>(_onCancelTransaction);
    add(const AiChatInitialize());
  }

  List<ChatMessage> get messages => _messages;
  bool get isListening => _isListening;
  bool get isAiInitialized => _aiService.isInitialized;

  bool _isFinanceRelated(String message) {
    final financeKeywords = [
      'uang', 'keuangan', 'tabung', 'tabungan', 'investasi', 'saham', 'reksa dana',
      'obligasi', 'bunga', 'kredit', 'hutang', 'piutang', 'cicilan', 'anggaran',
      'budget', 'pengeluaran', 'pemasukan', 'pendapatan', 'gaji', 'belanja',
      'hemat', 'nabung', 'inflasi', 'aset', 'liabilitas', 'laporan', 'neraca',
      'cashflow', 'arus kas', 'pajak', 'asuransi', 'dana darurat', 'finansial',
      'finance', 'money', 'saving', 'expense', 'income', 'spending', 'cost',
      'price', 'harga', 'bayar', 'transfer', 'bank', 'dompet', 'wallet',
      'premium', 'subscription', 'langganan', 'receipt', 'struk', 'nota',
    ];

    final lowerMessage = message.toLowerCase();
    if (lowerMessage.split(' ').length < 5) return true;

    return financeKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  void _appendMessage(ChatMessage message) {
    _messages.add(message);
  }

  Future<void> _onInitialize(
    AiChatInitialize event,
    Emitter<AiChatState> emit,
  ) async {
    final success = await _aiService.initialize();
    if (success) {
      _appendMessage(ChatMessage(
        text: '👋 Halo! Saya asisten keuanganmu.\n\n'
            'Kamu bisa:\n'
            '⌨️ Ketik — "makan siang 35rb"\n'
            '🎤 Tahan mic — ucapkan transaksimu\n'
            '📷 Tap scan — foto struk/nota\n\n'
            'Mau catat transaksi apa hari ini?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      _appendMessage(ChatMessage(
        text: '⚠️ AI belum terkonfigurasi.\n\n'
            'Tambahkan GROQ_API_KEY via --dart-define:\n'
            'flutter run --dart-define=GROQ_API_KEY=gsk_xxx\n\n'
            'Lalu restart aplikasi.',
        isUser: false,
        isRetryButton: true,
        timestamp: DateTime.now(),
      ));
    }
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onSendMessage(
    AiChatSendMessage event,
    Emitter<AiChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    if (!_isFinanceRelated(event.message)) {
      _appendMessage(ChatMessage(
        text: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _appendMessage(ChatMessage(
        text: 'Maaf, saya hanya bisa membantu terkait pertanyaan seputar keuangan. '
            'Apakah ada yang bisa saya bantu terkait keuangan Anda? 😊',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      emit(AiChatMessageAdded(messages: List.from(_messages)));
      return;
    }

    _appendMessage(ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    emit(AiChatLoading(messages: List.from(_messages)));

    _appendMessage(ChatMessage(
      text: '',
      isUser: false,
      isLoading: true,
      timestamp: DateTime.now(),
    ));
    emit(AiChatMessageAdded(messages: List.from(_messages)));

    try {
      final response = await _aiService.sendMessage(event.message, DateTime.now());
      _messages.removeLast();

      if (response.action == AiAction.addTransaction && response.transaction != null) {
        _appendMessage(ChatMessage(
          text: response.message,
          isUser: false,
          pendingTransaction: response.transaction,
          timestamp: DateTime.now(),
        ));
      } else {
        _appendMessage(ChatMessage(
          text: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.removeLast();
      if (!_aiService.isInitialized) {
        _appendMessage(ChatMessage(
          text: 'Tap tombol di bawah untuk coba koneksi ulang ke AI 🔄',
          isUser: false,
          isRetryButton: true,
          timestamp: DateTime.now(),
        ));
      } else {
        _appendMessage(ChatMessage(
          text: 'Maaf, ada gangguan. Coba lagi ya! 😅',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    }
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onScanImage(
    AiChatScanImage event,
    Emitter<AiChatState> emit,
  ) async {
    final file = await _ocrService.pickImage(fromCamera: event.source == 'camera');
    if (file == null) return;

    _appendMessage(ChatMessage(
      text: '[Memindai struk...]',
      isUser: true,
      imageFile: file,
      timestamp: DateTime.now(),
    ));
    _appendMessage(ChatMessage(
      text: '',
      isUser: false,
      isLoading: true,
      timestamp: DateTime.now(),
    ));
    emit(AiChatMessageAdded(messages: List.from(_messages)));

    try {
      final ocrResult = await _ocrService.extractText(file.path);
      if (!ocrResult.isSuccess || ocrResult.text.trim().isEmpty) {
        _messages.removeLast();
        _appendMessage(ChatMessage(
          text: 'Maaf, tidak ada teks yang bisa dibaca dari gambar ini. '
              'Coba foto yang lebih jelas ya! 📸',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        emit(AiChatMessageAdded(messages: List.from(_messages)));
        return;
      }

      if (ocrResult.engine == OcrEngine.tesseract) {
        _messages.removeLast();
        _appendMessage(ChatMessage(
          text: '📴 Mode offline — struk dibaca tanpa AI. '
              'Silakan cek hasilnya di layar review.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        emit(AiChatMessageAdded(messages: List.from(_messages)));
        return;
      }

      final prompt = _ocrService.buildReceiptPrompt(ocrResult.text);
      final response = await _aiService.sendMessage(prompt, DateTime.now());
      _messages.removeLast();

      if (response.action == AiAction.addTransaction && response.transaction != null) {
        _appendMessage(ChatMessage(
          text: response.message,
          isUser: false,
          pendingTransaction: response.transaction,
          timestamp: DateTime.now(),
        ));
      } else {
        _appendMessage(ChatMessage(
          text: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.removeLast();
      _appendMessage(ChatMessage(
        text: 'Gagal membaca gambar: $e',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onStartVoice(
    AiChatStartVoice event,
    Emitter<AiChatState> emit,
  ) async {
    final initialized = await _voiceService.initialize();
    if (!initialized) return;

    _recognizedWords = '';
    _isListening = true;

    await _voiceService.startListening(
      onResult: (result) {
        _recognizedWords = _voiceService.normalizeIndonesianNumbers(
          result.recognizedWords,
        );
      },
      onListeningStart: () {
        onVoiceStart?.call();
      },
      onListeningStop: () {
        _isListening = false;
        onVoiceStop?.call();
        final words = _recognizedWords.trim();
        if (words.isNotEmpty) {
          _recognizedWords = '';
          add(AiChatSendMessage(message: words));
        }
      },
    );
  }

  Future<void> _onStopVoice(
    AiChatStopVoice event,
    Emitter<AiChatState> emit,
  ) async {
    await _voiceService.stopListening();
    _isListening = false;
  }

  Future<void> _onConfirmTransaction(
    AiChatConfirmTransaction event,
    Emitter<AiChatState> emit,
  ) async {
    bool success = false;
    if (onConfirmTransactionExternal != null) {
      success = await onConfirmTransactionExternal!(event.transaction);
    }
    if (success) {
      _messages[event.messageIndex] = ChatMessage(
        text: 'Transaksi berhasil disimpan! ✅',
        isUser: false,
        timestamp: DateTime.now(),
      );
    } else {
      _messages[event.messageIndex] = ChatMessage(
        text: 'Gagal menyimpan transaksi. Coba lagi ya! 😅',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onCancelTransaction(
    AiChatCancelTransaction event,
    Emitter<AiChatState> emit,
  ) async {
    _messages[event.messageIndex] = ChatMessage(
      text: 'Transaksi dibatalkan.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onClear(
    AiChatClear event,
    Emitter<AiChatState> emit,
  ) async {
    _messages.clear();
    emit(const AiChatInitial());
  }

  Future<void> _onLoadHistory(
    AiChatLoadHistory event,
    Emitter<AiChatState> emit,
  ) async {
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }

  Future<void> _onRetry(
    AiChatRetry event,
    Emitter<AiChatState> emit,
  ) async {
    final success = await _aiService.reinitialize();
    _messages.removeWhere((m) => m.isRetryButton);
    if (success) {
      _appendMessage(ChatMessage(
        text: '✅ Berhasil terhubung ke AI! Silakan ketik transaksimu.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      _appendMessage(ChatMessage(
        text: 'Masih gagal. Pastikan API key benar dan internet aktif.',
        isUser: false,
        isRetryButton: true,
        timestamp: DateTime.now(),
      ));
    }
    emit(AiChatMessageAdded(messages: List.from(_messages)));
  }
}
