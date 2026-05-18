import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../services/local_oauth_server.dart';
import '../../../../services/pb_client.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckAuthStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isValid = PbClient.instance.authStore.isValid;
      if (isValid) {
        final user = PbClient.instance.authStore.record as RecordModel;
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthBloc] check error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await PbClient.instance.collection('users').authWithPassword(
        event.email,
        event.password,
      );

      final isValid = PbClient.instance.authStore.isValid;
      if (isValid) {
        final user = PbClient.instance.authStore.record as RecordModel;
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Login gagal. Silakan coba lagi'));
      }
    } catch (e) {
      debugPrint('[AuthBloc] login error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid') ||
          msg.contains('credentials') ||
          msg.contains('password')) {
        emit(const AuthError(message: 'Email atau password salah'));
      } else if (msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('socket')) {
        emit(const AuthError(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet kamu',
        ));
      } else if (msg.contains('timeout')) {
        emit(const AuthError(message: 'Koneksi timeout. Coba lagi'));
      } else {
        emit(const AuthError(message: 'Login gagal. Silakan coba lagi'));
      }
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authMethods = await PbClient.instance
          .collection('users')
          .listAuthMethods();

      final provider = authMethods.oauth2.providers
          .firstWhere((p) => p.name == 'google');

      const loopbackRedirect = 'http://127.0.0.1:8765/';

      // Replace PocketBase redirect_uri with loopback address
      final uri = Uri.parse(provider.authURL);
      final params = Map<String, String>.from(uri.queryParameters);
      params['redirect_uri'] = loopbackRedirect;
      final url = uri.replace(queryParameters: params);

      // Start local server BEFORE opening browser
      final resultFuture = LocalOAuthServer.start();

      // Buka di external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // Tunggu redirect ke local server
      final result = await resultFuture;
      final code = result['code'];

      if (code == null || code.isEmpty) {
        emit(const AuthError(message: 'Login gagal: kode tidak ditemukan'));
        return;
      }

      // Tukar code untuk token via PocketBase
      await PbClient.instance.collection('users').authWithOAuth2Code(
        'google',
        code,
        provider.codeVerifier,
        loopbackRedirect,
      );

      final isValid = PbClient.instance.authStore.isValid;
      if (isValid) {
        final user = PbClient.instance.authStore.record as RecordModel;
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthBloc] google login error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('socket')) {
        emit(const AuthError(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet kamu',
        ));
      } else if (msg.contains('timeout')) {
        emit(const AuthError(message: 'Koneksi timeout. Coba lagi'));
      } else {
        emit(const AuthError(message: 'Login gagal. Silakan coba lagi'));
      }
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      PbClient.instance.authStore.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pb_auth');
      emit(const AuthUnauthenticated());
    } catch (e) {
      debugPrint('[AuthBloc] logout error: $e');
      emit(const AuthUnauthenticated());
    }
  }
}
