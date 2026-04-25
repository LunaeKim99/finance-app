// === FILE: lib/screens/ai_chat_screen.dart ===
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/usage_provider.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../services/ocr_service.dart';
import '../utils/app_theme.dart';
import '../screens/upgrade_screen.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final bool isRetryButton;
  final TransactionModel? pendingTransaction;
  final File? imageFile;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.isRetryButton = false,
    this.pendingTransaction,
    this.imageFile,
    required this.timestamp,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final VoiceService _voiceService = VoiceService();
  final OcrService _ocrService = OcrService();
  // ignore: unused_field - used for loading states
  bool _isLoading = false;
  bool _isListening = false;
  String _recognizedWords = '';

  @override
  void initState() {
    super.initState();
    _initializeAiService();
  }

  Future<void> _initializeAiService() async {
    final success = await _aiService.initialize();
    
    if (success) {
      _addMessage(
        ChatMessage(
          text: '👋 Halo! Saya asisten keuanganmu.\n\n'
                'Kamu bisa:\n'
                '⌨️ Ketik — "makan siang 35rb"\n'
                '🎤 Tahan mic — ucapkan transaksimu\n'
                '📷 Tap scan — foto struk/nota\n\n'
                'Mau catat transaksi apa hari ini?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      _addMessage(
        ChatMessage(
          text: '⚠️ AI belum terkonfigurasi.\n\n'
                'Tambahkan GEMINI_API_KEY di file .env:\n'
                'GEMINI_API_KEY=api_key_kamu\n\n'
                'Lalu restart aplikasi.',
          isUser: false,
          isRetryButton: true,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final usageProvider = context.read<UsageProvider>();
    
    if (!usageProvider.canUseAiText()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Batas harian tercapai (10/10).'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradeScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    _textController.clear();
    _addMessage(
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _addMessage(
      ChatMessage(
        text: '',
        isUser: false,
        isLoading: true,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _aiService.sendMessage(text, DateTime.now());

      setState(() {
        _messages.removeLast();
        _isLoading = false;
      });
      
      await usageProvider.incrementAiText();

      if (response.action == AiAction.addTransaction && response.transaction != null) {
        _addMessage(
          ChatMessage(
            text: response.message,
            isUser: false,
            pendingTransaction: response.transaction,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _addMessage(
          ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _isLoading = false;
      });

      if (!_aiService.isInitialized) {
        _addMessage(ChatMessage(
          text: 'Tap tombol di bawah untuk coba koneksi ulang ke AI 🔄',
          isUser: false,
          isRetryButton: true,
          timestamp: DateTime.now(),
        ));
      } else {
        _addMessage(
          ChatMessage(
            text: 'Maaf, ada gangguan. Coba lagi ya! 😅',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> _startVoiceInput() async {
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon tidak tersedia di perangkat ini')),
        );
      }
      return;
    }

    _recognizedWords = '';

    await _voiceService.startListening(
      onResult: (result) {
        setState(() {
          _recognizedWords = result.recognizedWords;
          _textController.text = _recognizedWords;
        });
      },
      onListeningStart: () {
        setState(() => _isListening = true);
      },
      onListeningStop: () {
        if (!mounted) return;
        setState(() => _isListening = false);
        final words = _recognizedWords.trim();
        if (words.isNotEmpty) {
          _recognizedWords = '';
          _sendTextMessage(words);
        }
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
  }

  Future<void> _scanImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await _ocrService.pickImage(fromCamera: source == 'camera');
    if (file == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: '[Memindai struk...]',
        isUser: true,
        imageFile: file,
        timestamp: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        isLoading: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final ocrResult = await _ocrService.extractText(file.path);

      if (!ocrResult.isSuccess || ocrResult.text.trim().isEmpty) {
        _replaceLoadingWithMessage(
          'Maaf, tidak ada teks yang bisa dibaca dari gambar ini. '
          'Coba foto yang lebih jelas ya! 📸',
        );
        return;
      }

      if (ocrResult.engine == OcrEngine.tesseract) {
        _replaceLoadingWithMessage(
          '📴 Mode offline — struk dibaca tanpa AI. '
          'Silakan cek hasilnya di layar review.',
        );
        return;
      }

      final prompt = _ocrService.buildReceiptPrompt(ocrResult.text);
      final response = await _aiService.sendMessage(prompt, DateTime.now());
      _replaceLoadingWithResponse(response);
    } catch (e) {
      _replaceLoadingWithMessage('Gagal membaca gambar: $e');
    }
  }

  void _replaceLoadingWithResponse(AiResponse response) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      if (response.action == AiAction.addTransaction &&
          response.transaction != null) {
        _messages.add(ChatMessage(
          text: response.message,
          isUser: false,
          pendingTransaction: response.transaction,
          timestamp: DateTime.now(),
        ));
      } else {
        _messages.add(ChatMessage(
          text: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    });
    _scrollToBottom();
  }

  void _replaceLoadingWithMessage(String message) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _confirmTransaction(
      TransactionModel transaction, int messageIndex) async {
    final provider = context.read<TransactionProvider>();
    final success = await provider.addTransaction(transaction);

    if (success) {
      setState(() {
        _messages[messageIndex] = ChatMessage(
          text: 'Transaksi berhasil disimpan! ✅',
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    } else {
      setState(() {
        _messages[messageIndex] = ChatMessage(
          text: 'Gagal menyimpan transaksi. Coba lagi ya! 😅',
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
  }

  void _cancelTransaction(int messageIndex) {
    setState(() {
      _messages[messageIndex] = ChatMessage(
        text: 'Transaksi dibatalkan.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('Asisten Keuangan'),
            SizedBox(width: 8),
            Consumer<UsageProvider>(
              builder: (context, usageProvider, _) {
                if (usageProvider.isPremium) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sisa: ${usageProvider.remainingAiText}/10',
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  message,
                  index,
                  currencyFormat,
                  dateFormat,
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    int index,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Mengetik...'),
            ],
          ),
        ),
      );
    }

    if (message.isRetryButton) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPrimary : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _messages.removeWhere((m) => m.isRetryButton);
                  });
                  final success = await _aiService.reinitialize();
                  if (success && mounted) {
                    _addMessage(ChatMessage(
                      text: '✅ Berhasil terhubung ke AI! Silakan ketik transaksimu.',
                      isUser: false,
                      timestamp: DateTime.now(),
                    ));
                  } else if (mounted) {
                    _addMessage(ChatMessage(
                      text: 'Masih gagal. Pastikan API key benar dan internet aktif.',
                      isUser: false,
                      isRetryButton: true,
                      timestamp: DateTime.now(),
                    ));
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Hubungkan Ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (message.pendingTransaction != null) {
      final transaction = message.pendingTransaction!;
      final isIncome = transaction.type == 'income';
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isIncome ? AppTheme.lightGreen : AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isIncome ? AppTheme.primaryGreen : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? AppTheme.primaryGreen : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(transaction.amount),
                          style: TextStyle(
                            color: isIncome
                                ? AppTheme.primaryGreen
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dateFormat.format(transaction.date),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message.text),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelTransaction(index),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmTransaction(transaction, index),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primaryGreen
              : (isDark ? AppTheme.darkCard : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  message.imageFile!,
                  height: 150,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextPrimary : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: _scanImage,
              tooltip: 'Scan struk',
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'Mendengarkan...'
                      : 'Ceritakan transaksimu...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCardBorder : Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (text) {
                  if (text.isNotEmpty) _sendTextMessage(text);
                },
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onLongPressStart: (_) => _startVoiceInput(),
              onLongPressEnd: (_) => _stopVoiceInput(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.send_rounded, color: AppTheme.primaryGreen),
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) _sendTextMessage(text);
              },
            ),
          ],
        ),
      ),
    );
  }
}