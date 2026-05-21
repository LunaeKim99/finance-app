import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/screens/transaction/bloc/transaction_bloc.dart';
import '../presentation/screens/budget/bloc/budget_bloc.dart';
import '../presentation/screens/budget/bloc/budget_event.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/transaction/history_screen.dart';
import '../presentation/screens/report/report_screen.dart';
import '../presentation/screens/ai_chat/ai_chat_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/widgets/app_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _dataLoaded = false;

  static const _tabs = <Widget>[
    DashboardScreen(),
    HistoryScreen(),
    ReportScreen(),
    AiChatScreen(),
    SettingsScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
