import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pb_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  RecordModel? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RecordModel? get currentUser => _currentUser;
  String get userName => _currentUser?.data['name'] as String? ?? 'Pengguna';
  String get userEmail => _currentUser?.data['email'] as String? ?? '';
  String? get userAvatar => _currentUser?.data['avatarUrl'] as String?;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = PbClient.instance.authStore.isValid;
      _currentUser = PbClient.instance.authStore.isValid
          ? PbClient.instance.authStore.model as RecordModel?
          : null;
    } catch (e) {
      debugPrint('[Auth] initialize error: $e');
      _isLoggedIn = false;
      _currentUser = null;
    }

    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await PbClient.instance.collection('users').authWithOAuth2(
        'google',
        (Uri url) async {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        },
        query: {
          'redirectUrl':
              'https://equator-untainted-stank.ngrok-free.dev/_oauth/providers/google/callback',
        },
      );

      _isLoggedIn = PbClient.instance.authStore.isValid;
      _currentUser = PbClient.instance.authStore.isValid
          ? PbClient.instance.authStore.model as RecordModel?
          : null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Auth] signInWithGoogle error: $e');
      _isLoggedIn = false;
      _currentUser = null;
      _isLoading = false;

      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel')) {
        _errorMessage = 'Login dibatalkan';
      } else if (msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('socket')) {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet kamu';
      } else if (msg.contains('timeout')) {
        _errorMessage = 'Koneksi timeout. Coba lagi';
      } else {
        _errorMessage = 'Login gagal. Silakan coba lagi';
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    PbClient.instance.authStore.clear();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
