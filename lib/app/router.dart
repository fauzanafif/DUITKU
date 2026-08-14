import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/features/accounts/accounts_screen.dart';
import 'package:duitku/features/budget/budget_screen.dart';
import 'package:duitku/features/dashboard/dashboard_screen.dart';
import 'package:duitku/features/onboarding/onboarding_screen.dart';
import 'package:duitku/features/profile/profile_screen.dart';
import 'package:duitku/features/reports/reports_screen.dart';
import 'package:duitku/features/savings/savings_screen.dart';
import 'package:duitku/features/settings/backup_screen.dart';
import 'package:duitku/features/settings/categories_screen.dart';
import 'package:duitku/features/settings/security_screen.dart';
import 'package:duitku/features/settings/settings_screen.dart';
import 'package:duitku/features/shell/home_shell.dart';
import 'package:duitku/features/transactions/transaction_detail_screen.dart';
import 'package:duitku/features/transactions/transaction_form_screen.dart';
import 'package:duitku/features/transactions/transactions_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod's async settings into GoRouter so the onboarding
/// redirect re-evaluates as soon as settings finish loading.
class _SettingsRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SettingsRefreshNotifier();
  ref.listen(settingsProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) return null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!settings.onboardingCompleted && !onboarding) return '/onboarding';
      if (settings.onboardingCompleted && onboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/transactions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionFormScreen(
          initialType: _parseType(state.uri.queryParameters['type']),
          withdrawCashMode: state.uri.queryParameters['mode'] == 'withdraw',
        ),
      ),
      GoRoute(
        path: '/transactions/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionFormScreen(
          transactionId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/transactions/detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TransactionDetailScreen(transactionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/budget',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/savings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'categories',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: 'security',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SecurityScreen(),
          ),
          GoRoute(
            path: 'backup',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const BackupScreen(),
          ),
        ],
      ),
    ],
  );
});

TransactionType _parseType(String? raw) {
  for (final type in TransactionType.values) {
    if (type.name == raw) return type;
  }
  return TransactionType.expense;
}
