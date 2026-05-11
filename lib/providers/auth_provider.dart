import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pb_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  RecordModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  RecordModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthState();
  }

  PocketBase get _pb => PbClient.instance;

  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = _pb.authStore.isValid;
      _currentUser = _pb.authStore.isValid ? _pb.authStore.model : null;
    } catch (e) {
      debugPrint('[Auth] checkAuthState error: $e');
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
      final authData = await _pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          await _launchUrl(url);
        },
        createData: {
          'name': '',
        },
      );

      _isLoggedIn = authData != null && _pb.authStore.isValid;
      _currentUser = _isLoggedIn ? _pb.authStore.model : null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return _isLoggedIn;
    } catch (e) {
      debugPrint('[Auth] signInWithGoogle error: $e');
      _isLoggedIn = false;
      _currentUser = null;
      _isLoading = false;
      _errorMessage = 'Gagal masuk dengan Google. Coba lagi ya! 😅';
      notifyListeners();
      return false;
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _errorMessage = 'Tidak bisa membuka browser untuk login.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Auth] launchUrl error: $e');
      _errorMessage = 'Gagal membuka halaman login.';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _pb.authStore.clear();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
