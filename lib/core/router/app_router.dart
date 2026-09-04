import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/features/auth/presentation/auth_provider.dart';
import 'package:jm_imports/features/auth/presentation/biometric_lock_screen.dart';
import 'package:jm_imports/features/auth/presentation/login_screen.dart';
import 'package:jm_imports/features/dashboard/presentation/daily_log_screen.dart';
import 'package:jm_imports/features/dashboard/presentation/dashboard_screen.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_screen.dart';
import 'package:jm_imports/features/inventory/presentation/spare_part_form_screen.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_kanban_screen.dart';
import 'package:jm_imports/features/repairs/presentation/repair_detail_screen.dart';
import 'package:jm_imports/features/repairs/presentation/repair_form_screen.dart';
import 'package:jm_imports/features/sales/presentation/sales_screen.dart';
import 'package:jm_imports/features/sales/presentation/new_sale_screen.dart';
import 'package:jm_imports/shell/main_shell.dart';

import 'package:jm_imports/features/auth/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorRepairsKey = GlobalKey<NavigatorState>(debugLabel: 'repairs');
final _shellNavigatorInventoryKey = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shellNavigatorSalesKey = GlobalKey<NavigatorState>(debugLabel: 'sales');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) => notifyListeners());
    _ref.listen(isBiometricUnlockedProvider, (previous, next) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isSplash = state.matchedLocation == '/splash';

      // 0. While auth state is initializing, show splash screen
      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final user = authState.value;
      final isBiometricUnlocked = ref.read(isBiometricUnlockedProvider);

      final isLoggingIn = state.matchedLocation == '/login';
      final isBiometricScreen = state.matchedLocation == '/biometric-lock';

      // 1. If not logged in, force to /login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. If logged in, check if biometric unlock has passed for this session
      if (!isBiometricUnlocked) {
        return isBiometricScreen ? null : '/biometric-lock';
      }

      // 3. If logged in and unlocked, redirect away from auth/splash screens to /dashboard
      if (isLoggingIn || isBiometricScreen || isSplash) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/biometric-lock',
        builder: (context, state) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: '/daily-log',
        builder: (context, state) => const DailyLogScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorRepairsKey,
            routes: [
              GoRoute(
                path: '/repairs',
                builder: (context, state) => const RepairsKanbanScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const RepairFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return RepairDetailScreen(repairId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInventoryKey,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SparePartFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SparePartFormScreen(sparePartId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSalesKey,
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SalesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const NewSaleScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
