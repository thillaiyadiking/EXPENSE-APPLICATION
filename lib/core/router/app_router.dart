import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pocketflow/presentation/screens/add_transaction_screen.dart';
import 'package:pocketflow/presentation/screens/analytics_screen.dart';
import 'package:pocketflow/presentation/screens/backup_screen.dart';
import 'package:pocketflow/presentation/screens/budget_screen.dart';
import 'package:pocketflow/presentation/screens/categories_screen.dart';
import 'package:pocketflow/presentation/screens/home_screen.dart';
import 'package:pocketflow/presentation/screens/lock_screen.dart';
import 'package:pocketflow/presentation/screens/onboarding_screen.dart';
import 'package:pocketflow/presentation/screens/search_screen.dart';
import 'package:pocketflow/presentation/screens/settings_screen.dart';
import 'package:pocketflow/presentation/screens/shell_screen.dart';
import 'package:pocketflow/presentation/screens/splash_screen.dart';
import 'package:pocketflow/presentation/screens/transaction_detail_screen.dart';
import 'package:pocketflow/providers/providers.dart';
import 'package:pocketflow/services/home_widget_service.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Requests navigation from a home-widget tap or launcher shortcut.
void requestExternalRoute(WidgetRef ref, String route) {
  ref.read(pendingRouteProvider.notifier).state = route;

  final unlocked = ref.read(appUnlockedProvider);
  if (!unlocked) return;

  ref.read(pendingRouteProvider.notifier).state = null;
  ref.read(routerProvider).go(route);
}

/// Maps widget / deep-link URIs (pocketflow://…) to in-app GoRouter paths.
String? mapExternalUri(Uri uri) {
  if (uri.scheme == 'pocketflow') {
    return HomeWidgetService.routeFromUri(uri);
  }
  // Some launchers pass the full URI string as the path.
  final raw = uri.toString();
  if (raw.startsWith('pocketflow:')) {
    try {
      return HomeWidgetService.routeFromUri(Uri.parse(raw));
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Notifies GoRouter when auth/unlock state changes without recreating the router.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<bool>(appUnlockedProvider, (previous, next) {
      // Defer so we never refresh/redirect mid provider rebuild.
      Future.microtask(notifyListeners);
    });
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    // Widget taps send pocketflow://… — don't use that as the initial route.
    overridePlatformDefaultLocation: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final mapped = mapExternalUri(state.uri);
      if (mapped != null) {
        final unlocked = ref.read(appUnlockedProvider);
        final settings = ref.read(settingsRepositoryProvider).get();
        final needsLock = settings.pinEnabled || settings.biometricEnabled;
        if (needsLock && !unlocked) {
          ref.read(pendingRouteProvider.notifier).state = mapped;
          return '/lock';
        }
        if (!settings.onboardingComplete && mapped != '/onboarding') {
          ref.read(pendingRouteProvider.notifier).state = mapped;
          return '/onboarding';
        }
        return mapped;
      }

      final path = state.uri.path;
      if (path == '/splash') return null;

      final unlocked = ref.read(appUnlockedProvider);
      final settings = ref.read(settingsRepositoryProvider).get();
      final needsLock = settings.pinEnabled || settings.biometricEnabled;
      final isOnboarding = path == '/onboarding';
      final isReplay = state.uri.queryParameters['replay'] == '1';

      // First-run / replay onboarding is allowed while unlocked (or no lock).
      if (isOnboarding) {
        if (needsLock && !unlocked && !isReplay) return '/lock';
        return null;
      }

      if (needsLock && !unlocked && path != '/lock') {
        return '/lock';
      }
      if (unlocked && path == '/lock') {
        final pending = ref.read(pendingRouteProvider);
        if (pending != null && pending.isNotEmpty) {
          ref.read(pendingRouteProvider.notifier).state = null;
          return pending;
        }
        if (!settings.onboardingComplete) return '/onboarding';
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final replay = state.uri.queryParameters['replay'] == '1';
          return OnboardingScreen(replay: replay);
        },
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BudgetScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddTransactionScreen(quickType: type),
            transitionsBuilder: (context, animation, secondary, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/edit/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddTransactionScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/transaction/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: TransactionDetailScreen(transactionId: id),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/backup',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const BackupScreen(),
      ),
    ],
  );
});
