import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/accounting/presentation/screens/transaction_list_screen.dart';
import '../../features/accounting/presentation/screens/transaction_form_screen.dart';
import '../../features/security/presentation/screens/security_test_screen.dart';
import '../../features/settings/presentation/screens/i18n_test_screen.dart';
import '../constants/app_constants.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppConstants.homeRoute,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        pageBuilder: (context, state) => const MaterialPage(
          child: TransactionListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'transaction_new',
            pageBuilder: (context, state) => const MaterialPage(
              child: TransactionFormScreen(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: AppConstants.analyticsRoute,
        name: 'analytics',
        pageBuilder: (context, state) => const MaterialPage(
          child: Placeholder(), // TODO: Analytics Screen
        ),
      ),

      GoRoute(
        path: AppConstants.settingsRoute,
        name: 'settings',
        pageBuilder: (context, state) => const MaterialPage(
          child: Placeholder(), // TODO: Settings Screen
        ),
      ),

      // 安全模块测试屏幕
      GoRoute(
        path: '/security-test',
        name: 'security_test',
        pageBuilder: (context, state) => const MaterialPage(
          child: SecurityTestScreen(),
        ),
      ),

      // 国际化测试屏幕
      GoRoute(
        path: '/i18n-test',
        name: 'i18n_test',
        pageBuilder: (context, state) => const MaterialPage(
          child: I18nTestScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    ),
  );
}
