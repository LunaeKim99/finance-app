import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'UWANGKU',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asisten Keuangan Pribadi Anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF66BB6A),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 2),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoading) {
                    return const Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Memproses...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        if (auth.errorMessage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              auth.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => auth.signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: Image.asset(
                              'assets/images/google_logo.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                              ),
                            ),
                            label: const Text(
                              'Lanjutkan dengan Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
