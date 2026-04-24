// === FILE: lib/main.dart ===
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/ai_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);
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
              home: const AppShell(),
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Personal Finance',
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
            home: const AppShell(),
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
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
              icon: Icon(CupertinoIcons.chart_pie),
              label: 'Laporan',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(_getTitle(index)),
            ),
            child: SafeArea(
              child: _screens[index],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Laporan',
          ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'ai',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                  tooltip: 'Catat dengan AI',
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Tambah Manual',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Personal Finance';
      case 1:
        return 'Riwayat Transaksi';
      case 2:
        return 'Laporan';
      default:
        return 'Personal Finance';
    }
  }
}