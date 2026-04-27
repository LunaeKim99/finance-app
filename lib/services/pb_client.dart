import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/app_config.dart';

class PbClient {
  static PocketBase? _instance;

  static PocketBase get instance {
    _instance ??= PocketBase(_baseUrl);
    return _instance!;
  }

  static String get _baseUrl {
    // Priority: --dart-define > AppConfig > default platform detection
    final fromDefine = String.fromEnvironment('PB_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    
    if (AppConfig.pbBaseUrl.isNotEmpty) return AppConfig.pbBaseUrl;

    if (kIsWeb) {
      return 'http://localhost:8090';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8090';
    }

    if (Platform.isIOS) {
      return 'http://127.0.0.1:8090';
    }

    return 'http://localhost:8090';
  }

  static Future<bool> isConnected() async {
    try {
      await instance.health.check();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void reset() => _instance = null;
}