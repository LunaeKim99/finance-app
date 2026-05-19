import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/screens/transaction/bloc/transaction_bloc.dart';
import '../presentation/screens/budget/bloc/budget_bloc.dart';
import '../presentation/screens/budget/bloc/budget_event.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/transaction/history_screen.dart';
import '../presentation/screens/transaction/add_transaction_screen.dart';
import '../presentation/screens/report/report_screen.dart';
import '../presentation/screens/ai_chat/bloc/ai_chat_bloc.dart';
import '../presentation/screens/ai_chat/ai_chat_screen.dart';
import '../presentation/screens/budget/budget_screen.dart';
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  GlobalKey<BudgetScreenState>? _budgetScreenKey;
  List<Widget>? _screens;
  bool _dataLoaded = false;

  List<Widget> get _screenList {
    _screens ??= [
      const DashboardScreen(),
      const HistoryScreen(),
      _budgetScreenKey != null ? BudgetScreen(key: _budgetScreenKey) : const BudgetScreen(),
      const ReportScreen(),
      BlocProvider(
        create: (_) => AiChatBloc(),
        child: const AiChatScreen(),
      ),
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
    if (!_dataLoaded) {
      _dataLoaded = true;
      context.read<TransactionBloc>().ensureInitialized();
      final now = DateTime.now();
      context.read<BudgetBloc>().add(BudgetLoadRequested(month: now.month, year: now.year));
    }
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
      case 1:
        return FloatingActionButton(
          key: const ValueKey('fab_history'),
          mini: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
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
