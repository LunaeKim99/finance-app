import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/local_oauth_server.dart';
import '../../services/pb_client.dart';
import '../datasources/local/sqlite_helper.dart';
import '../datasources/sync_queue_helper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SqliteHelper _sqliteHelper;
  final SyncQueueHelper _syncQueue;

  AuthRepositoryImpl()
      : _sqliteHelper = SqliteHelper(),
        _syncQueue = SyncQueueHelper();

  PocketBase get _pb => PbClient.instance;

  @override
  bool get isLoggedIn => _pb.authStore.isValid;

  @override
  String? get userId => _pb.authStore.record?.id;

  @override
  Future<void> initialize() async {
    // Already initialized via PbClient.init() in main.dart
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (!_pb.authStore.isValid) return null;
    final record = _pb.authStore.record as RecordModel;
    return UserProfile(
      id: record.id,
      name: record.data['name'] as String? ?? 'Pengguna',
      email: record.data['email'] as String? ?? '',
      avatarUrl: record.data['avatarUrl'] as String?,
    );
  }

  @override
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
      return _pb.authStore.isValid;
    } catch (e) {
      debugPrint('[AuthRepo] signInWithEmail error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      final authMethods = await _pb.collection('users').listAuthMethods();

      final provider = authMethods.oauth2.providers
          .firstWhere((p) => p.name == 'google');

      const loopbackRedirect = 'http://127.0.0.1:8765/';

      final uri = Uri.parse(provider.authURL);
      final params = Map<String, String>.from(uri.queryParameters);
      params['redirect_uri'] = loopbackRedirect;
      final url = uri.replace(queryParameters: params);

      final resultFuture = LocalOAuthServer.start();

      await launchUrl(url, mode: LaunchMode.externalApplication);

      final result = await resultFuture;
      final code = result['code'];

      if (code == null || code.isEmpty) {
        throw Exception('Google login failed: no auth code');
      }

      await _pb.collection('users').authWithOAuth2Code(
        'google',
        code,
        provider.codeVerifier,
        loopbackRedirect,
      );

      return _pb.authStore.isValid;
    } catch (e) {
      debugPrint('[AuthRepo] signInWithGoogle error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth');
    _pb.authStore.clear();
  }

  @override
  Future<void> updateProfile(String name) async {
    final uid = userId;
    if (uid == null) throw Exception('User tidak terautentikasi');
    await _pb.collection('users').update(uid, body: {'name': name});
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final uid = userId;
    if (uid == null) throw Exception('User tidak terautentikasi');
    await _pb.collection('users').update(uid, body: {
      'oldPassword': currentPassword,
      'password': newPassword,
      'passwordConfirm': newPassword,
    });
  }

  @override
  Future<void> deleteAccount() async {
    final uid = userId;
    if (uid == null) throw Exception('User tidak terautentikasi');

    // 1. Hapus data user dari PocketBase
    try {
      await _deleteUserDataFromPB(uid);
    } catch (e) {
      debugPrint('[AuthRepo] deleteUserData error (non-fatal): $e');
    }

    // 2. Hapus user dari PocketBase
    try {
      await _pb.collection('users').delete(uid);
    } catch (e) {
      debugPrint('[AuthRepo] deleteUser error: $e');
    }

    // 3. Hapus local SQLite
    try {
      await _sqliteHelper.dropAllData();
    } catch (e) {
      debugPrint('[AuthRepo] dropSQLite error: $e');
    }

    // 4. Hapus sync queue
    try {
      await _syncQueue.clearAll();
    } catch (e) {
      debugPrint('[AuthRepo] clearSyncQueue error: $e');
    }

    // 5. Hapus SharedPreferences & auth
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _pb.authStore.clear();
  }

  Future<void> _deleteUserDataFromPB(String uid) async {
    // Hapus transaksi
    try {
      final txResult = await _pb.collection('transactions').getFullList(
        filter: 'user = "$uid"',
      );
      for (final item in txResult) {
        await _pb.collection('transactions').delete(item.id);
      }
    } catch (e) {
      debugPrint('[AuthRepo] delete transactions: $e');
    }

    // Hapus aset
    try {
      final assetResult = await _pb.collection('assets').getFullList(
        filter: 'user = "$uid"',
      );
      for (final item in assetResult) {
        await _pb.collection('assets').delete(item.id);
      }
    } catch (e) {
      debugPrint('[AuthRepo] delete assets: $e');
    }

    // Hapus hutang
    try {
      final debtResult = await _pb.collection('debts').getFullList(
        filter: 'user = "$uid"',
      );
      for (final item in debtResult) {
        await _pb.collection('debts').delete(item.id);
      }
    } catch (e) {
      debugPrint('[AuthRepo] delete debts: $e');
    }

    // Hapus budget
    try {
      final budgetResult = await _pb.collection('budgets').getFullList(
        filter: 'user = "$uid"',
      );
      for (final item in budgetResult) {
        await _pb.collection('budgets').delete(item.id);
      }
    } catch (e) {
      debugPrint('[AuthRepo] delete budgets: $e');
    }
  }
}
