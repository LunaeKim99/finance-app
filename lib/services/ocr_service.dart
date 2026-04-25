// === FILE: lib/services/ocr_service.dart ===
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OcrService {
  static OcrService? _instance;
  factory OcrService() {
    _instance ??= OcrService._internal();
    return _instance!;
  }
  OcrService._internal();

  Future<OcrResult> extractText(String imagePath) async {
    final isOnline = await _checkConnectivity();

    if (isOnline) {
      return await _extractWithMlKit(imagePath);
    } else {
      return await _extractWithTesseract(imagePath);
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<OcrResult> _extractWithMlKit(String imagePath) async {
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      return OcrResult(
        text: recognizedText.text,
        engine: OcrEngine.mlKit,
        isSuccess: recognizedText.text.isNotEmpty,
        errorMessage: recognizedText.text.isEmpty
            ? 'Tidak ada teks yang terdeteksi'
            : null,
      );
    } catch (e) {
      debugPrint('ML Kit error: $e — mencoba Tesseract...');
      return await _extractWithTesseract(imagePath);
    } finally {
      textRecognizer.close();
    }
  }

  Future<OcrResult> _extractWithTesseract(String imagePath) async {
    try {
      final tessDataPath = await _prepareTessData();

      final result = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'ind+eng',
        args: {
          'preserve_interword_spaces': '1',
          'tessdata-dir': tessDataPath,
        },
      );

      final isNotEmpty = result.isNotEmpty;
      return OcrResult(
        text: result,
        engine: OcrEngine.tesseract,
        isSuccess: isNotEmpty,
        errorMessage: isNotEmpty
            ? null
            : 'Tesseract tidak dapat membaca teks dari gambar ini',
      );
    } catch (e) {
      debugPrint('Tesseract error: $e');
      return OcrResult(
        text: '',
        engine: OcrEngine.tesseract,
        isSuccess: false,
        errorMessage: 'Gagal membaca teks: ${e.toString()}',
      );
    }
  }

  Future<String> _prepareTessData() async {
    final tempDir = await getTemporaryDirectory();
    final tessDataDir = Directory(path.join(tempDir.path, 'tessdata'));

    if (!await tessDataDir.exists()) {
      await tessDataDir.create(recursive: true);
    }

    await _copyAssetToTemp(
      'assets/tessdata/ind.traineddata',
      path.join(tessDataDir.path, 'ind.traineddata'),
    );

    await _copyAssetToTemp(
      'assets/tessdata/eng.traineddata',
      path.join(tessDataDir.path, 'eng.traineddata'),
    );

    return tessDataDir.path;
  }

  Future<void> _copyAssetToTemp(String assetPath, String targetPath) async {
    final targetFile = File(targetPath);
    if (await targetFile.exists()) return;

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await targetFile.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Gagal copy tessdata $assetPath: $e');
    }
  }

  String buildReceiptPrompt(String rawText) {
    return '''
Kamu adalah asisten keuangan. Analisis teks struk belanja berikut dan ekstrak
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
  ]
}

Teks struk:
$rawText
''';
  }

  Future<File?> pickImage({bool fromCamera = true}) async {
    try {
      final imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
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
}

enum OcrEngine { mlKit, tesseract }

class OcrResult {
  final String text;
  final OcrEngine engine;
  final bool isSuccess;
  final String? errorMessage;

  const OcrResult({
    required this.text,
    required this.engine,
    required this.isSuccess,
    this.errorMessage,
  });

  String get engineName {
    switch (engine) {
      case OcrEngine.mlKit:
        return 'Google ML Kit';
      case OcrEngine.tesseract:
        return 'Mode Offline (Tesseract)';
    }
  }
}