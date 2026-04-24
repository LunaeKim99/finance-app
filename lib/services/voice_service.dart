// === FILE: lib/services/voice_service.dart ===
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Simpan callback agar bisa dipanggil saat stop/cancel
  Function()? _onListeningStopCallback;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Voice error: $error'),
      onStatus: (status) {
        debugPrint('Voice status: $status');
        // Jika speech engine berhenti otomatis, panggil callback
        if (status == 'done' || status == 'notListening') {
          if (_isListening) {
            _isListening = false;
            _onListeningStopCallback?.call();
          }
        }
      },
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(SpeechRecognitionResult) onResult,
    required Function() onListeningStart,
    required Function() onListeningStop,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }
    if (_isListening) return;

    // Simpan callback untuk dipanggil nanti
    _onListeningStopCallback = onListeningStop;
    _isListening = true;
    onListeningStart();

    final locales = await _speech.locales();
    final hasIndonesian = locales.any((l) => l.localeId.contains('id'));
    final selectedLocale = hasIndonesian ? 'id_ID' : '';

    await _speech.listen(
      onResult: onResult,
      localeId: selectedLocale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speech.stop();
    _onListeningStopCallback?.call();
    _onListeningStopCallback = null;
  }

  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
    _onListeningStopCallback?.call();
    _onListeningStopCallback = null;
  }

  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }
}