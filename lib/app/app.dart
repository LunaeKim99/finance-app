import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/usage_repository_impl.dart';
import '../presentation/blocs/settings/settings_bloc.dart';
import '../presentation/blocs/settings/settings_state.dart';
import '../presentation/blocs/category/category_bloc.dart';
import '../presentation/blocs/usage/usage_bloc.dart';
import '../presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import '../presentation/screens/auth/bloc/auth_bloc.dart';
import '../presentation/screens/auth/bloc/auth_state.dart';
import '../presentation/screens/transaction/bloc/transaction_bloc.dart';
import '../presentation/screens/budget/bloc/budget_bloc.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: AuthRepositoryImpl(),
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(
            settingsRepository: SettingsRepositoryImpl(),
          ),
        ),
        BlocProvider<TransactionBloc>(
          create: (_) => TransactionBloc(),
        ),
        BlocProvider<BudgetBloc>(
          create: (_) => BudgetBloc(),
        ),
        BlocProvider<UsageBloc>(
          create: (_) => UsageBloc(
            usageRepository: UsageRepositoryImpl(),
          ),
        ),
        BlocProvider<AiChatBloc>(
          create: (_) => AiChatBloc(),
        ),
        BlocProvider<CategoryBloc>(
          create: (_) => CategoryBloc(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final isDark = settingsState is SettingsLoaded
                ? settingsState.settings.isDarkMode
                : false;

            if (Platform.isIOS) {
              return CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: CupertinoThemeData(
                  primaryColor: AppColors.primary,
                  brightness: isDark ? Brightness.dark : Brightness.light,
                  scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
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
              navigatorKey: appNavigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'UWANGKU',
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
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
    );
  }
}
