import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../services/pb_client.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckAuthStatus);
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
        final user = PbClient.instance.authStore.model as RecordModel;
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthBloc] check error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await PbClient.instance.collection('users').authWithOAuth2(
        'google',
        (Uri url) async {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        },
      );

      final isValid = PbClient.instance.authStore.isValid;
      if (isValid) {
        final user = PbClient.instance.authStore.model as RecordModel;
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }

      try {
        await launchUrl(
          Uri.parse('com.example.uangku://oauth/callback'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[AuthBloc] google login error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel')) {
        emit(const AuthError(message: 'Login dibatalkan'));
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
