import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class _NgrokHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['ngrok-skip-browser-warning'] = 'true';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class PbClient {
  static PocketBase? _instance;

  static PocketBase get instance {
    assert(_instance != null, 'PbClient not initialized. Call PbClient.init() first');
    return _instance!;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
    );

    _instance = PocketBase(
      _baseUrl,
      httpClientFactory: () => _NgrokHttpClient(),
      authStore: store,
    );
  }

  static String get _baseUrl {
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
      await instance.health.check().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  static void reset() {
    _instance = null;
  }
}
