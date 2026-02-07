import 'package:flutter/material.dart';

import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../dual_ledger/presentation/screens/dual_ledger_screen.dart';

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
          _SettingsPlaceholder(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings (coming soon)')),
    );
  }
}
