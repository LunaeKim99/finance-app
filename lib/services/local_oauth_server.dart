import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalOAuthServer {
  static const int port = 8765;

  static Future<Map<String, String?>> start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );

    debugPrint('[LocalOAuthServer] listening on http://127.0.0.1:$port');

    try {
      final request = await server.first;

      final uri = request.uri;
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      final redirectUri = Uri(
        scheme: 'com.example.uangku',
        host: 'oauth',
        path: 'callback',
        queryParameters: {'code': code, 'state': state},
      );

      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="0;url=$redirectUri">
</head>
<body style="display:flex;justify-content:center;align-items:center;min-height:100vh;font-family:sans-serif">
  <p>Login berhasil. Mengembalikan ke aplikasi...</p>
  <script>window.location.href="$redirectUri"; window.close();</script>
</body>
</html>''');
      await request.response.close();

      return {'code': code, 'state': state};
    } finally {
      await server.close(force: true);
      debugPrint('[LocalOAuthServer] closed');
    }
  }
}
