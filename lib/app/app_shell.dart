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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const HistoryScreen();
      case 2:
        return const ReportScreen();
      case 3:
        return const AiChatScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
