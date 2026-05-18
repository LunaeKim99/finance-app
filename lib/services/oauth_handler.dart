import 'dart:async';
import 'package:flutter/foundation.dart';

class OAuthHandler {
  static Completer<Uri>? _completer;
  static Uri? _pendingRedirect;

  static Future<Uri> start(Uri authUrl) async {
    if (_pendingRedirect != null) {
      final uri = _pendingRedirect!;
      _pendingRedirect = null;
      return uri;
    }
    _completer = Completer<Uri>();
    return _completer!.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw TimeoutException('OAuth timeout'),
    );
  }

  static void onRedirect(Uri uri) {
    if (_completer != null && !_completer!.isCompleted) {
      debugPrint('[OAuthHandler] redirect received: $uri');
      _completer!.complete(uri);
      _completer = null;
    } else {
      _pendingRedirect = uri;
    }
  }

  static void cancel() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(StateError('OAuth dibatalkan'));
      _completer = null;
    }
    _pendingRedirect = null;
  }
}
