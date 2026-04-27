// === FILE: lib/main.dart ===
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/usage_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/budget_screen.dart';
import 'utils/error_handler.dart';
import 'database/pb_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await PbHelper().initialize();
  runApp(const FinanceApp());
}

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
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  GlobalKey<BudgetScreenState>? _budgetScreenKey;
  List<Widget>? _screens;

  List<Widget> get _screenList {
    _screens ??= [
      const DashboardScreen(),
      const HistoryScreen(),
      _budgetScreenKey != null ? BudgetScreen(key: _budgetScreenKey) : const BudgetScreen(),
      const ReportScreen(),
      const AiChatScreen(),
    ];
    return _screens!;
  }

  @override
  void initState() {
    super.initState();
    _budgetScreenKey = GlobalKey<BudgetScreenState>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TransactionProvider>();
    provider.onError = (message) {
      ErrorHandler.showError(context, message);
    };
    provider.onSuccess = (message) {
      ErrorHandler.showSuccess(context, message);
    };
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  int get _activeNavIndex => _currentIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFF4CAF50);
    final inactiveColor = isDark ? Colors.grey : Colors.grey;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.clock),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.money_dollar_circle),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_pie),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2),
              label: 'AI Chat',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(_getTitle(index)),
            ),
            child: SafeArea(
              child: _screenList[index],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screenList,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              children: [
                _buildNavItem(
                  navIndex: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  navIndex: 1,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Riwayat',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  navIndex: 2,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Budget',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  navIndex: 3,
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Laporan',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  navIndex: 4,
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy_rounded,
                  label: 'AI Chat',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildTabFab(_currentIndex),
      ),
    );
  }

  Widget _buildNavItem({
    required int navIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = _activeNavIndex == navIndex;

    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(navIndex),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'UWANGKU';
      case 1:
        return 'Riwayat Transaksi';
      case 2:
        return 'Budget Bulanan';
      case 3:
        return 'Laporan';
      case 4:
        return 'AI Chat';
      default:
        return 'UWANGKU';
    }
  }

  Widget _buildTabFab(int index) {
    switch (index) {
      case 0:
        return FloatingActionButton.extended(
          key: const ValueKey('fab_home'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah Transaksi'),
        );
      case 2:
        return FloatingActionButton.extended(
          key: const ValueKey('fab_budget'),
          onPressed: () {
            _budgetScreenKey?.currentState?.showAddBudgetDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah Budget'),
        );
      default:
        return const SizedBox.shrink(key: ValueKey('fab_hidden'));
    }
  }
}