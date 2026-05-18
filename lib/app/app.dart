import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/transaction_provider.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/usage_provider.dart';
import '../presentation/providers/budget_provider.dart';
import '../presentation/screens/auth/bloc/auth_bloc.dart';
import '../presentation/screens/auth/bloc/auth_state.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = TransactionProvider();
            provider.initialize().then((_) => provider.loadTransactions());
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = UsageProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = BudgetProvider();
            provider.initialize();
            return provider;
          },
        ),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          },
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              if (Platform.isIOS) {
                return CupertinoApp(
                  debugShowCheckedModeBanner: false,
                  theme: CupertinoThemeData(
                    primaryColor: const Color(0xFF4CAF50),
                    brightness: themeProvider.isDarkMode
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  locale: const Locale('id', 'ID'),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [Locale('id', 'ID')],
                  home: const SplashScreen(),
                );
              }

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'UWANGKU',
                themeMode: themeProvider.themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF4CAF50),
                    brightness: Brightness.light,
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  platform: TargetPlatform.android,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF4CAF50),
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                ),
                locale: const Locale('id', 'ID'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('id', 'ID')],
                home: const SplashScreen(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
