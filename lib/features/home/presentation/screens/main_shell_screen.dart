import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../dual_ledger/presentation/screens/dual_ledger_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main navigation shell with BottomNavigationBar.
///
/// Provides tab navigation between Home (Ledger), Analytics, and Settings.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DualLedgerScreen(bookId: widget.bookId),
          AnalyticsScreen(bookId: widget.bookId),
          SettingsScreen(bookId: widget.bookId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: S.of(context).ledger,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: S.of(context).analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: S.of(context).settings,
          ),
        ],
      ),
    );
  }
}
