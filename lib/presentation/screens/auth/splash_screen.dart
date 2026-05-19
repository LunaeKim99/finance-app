import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/app_shell.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_state.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    context.read<AuthBloc>().add(const AuthCheckStatus());
    await context.read<TransactionBloc>().ensureInitialized();
    await ExchangeRateService.instance.initialize();

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final state = context.read<AuthBloc>().state;
    final Widget destination = state is AuthAuthenticated
        ? const AppShell()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE8F5E9),
            ],
            stops: [0.3, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'UWANGKU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Asisten Keuangan Pribadi Anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF66BB6A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 80),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: const Color(0xFFC8E6C9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF50),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                final isConnected = state is TransactionLoaded ? state.isOnline : false;
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Tersambung ke server' : 'Mode offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
