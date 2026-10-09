import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Always leave splash — MIUI devices can hang forever on notification /
    // widget plugin calls if we await them on the critical path.
    try {
      final seed = ref.read(seedServiceProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);

      void handle(String route) => requestExternalRoute(ref, route);

      // Soft-init launchers with a short timeout; never block navigation.
      await Future.wait([
        ref
            .read(homeWidgetServiceProvider)
            .init(onRouteRequested: handle)
            .timeout(const Duration(seconds: 2), onTimeout: () {}),
        ref
            .read(appShortcutsServiceProvider)
            .init(onRouteRequested: handle)
            .timeout(const Duration(seconds: 2), onTimeout: () {}),
      ]).catchError((_) => <void>[]);

      if (!mounted) return;

      await seed.ensureDefaults().timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final settings = settingsRepo.get();

      // Defer reminders + widget sync — these hang on some Xiaomi builds.
      unawaited(
        ref
            .read(notificationServiceProvider)
            .scheduleBudgetReminder(
              hour: settings.reminderHour,
              minute: settings.reminderMinute,
              enabled: settings.budgetRemindersEnabled,
            )
            .timeout(const Duration(seconds: 6), onTimeout: () {}),
      );
      unawaited(
        ref
            .read(transactionControllerProvider)
            .syncHomeWidget()
            .timeout(const Duration(seconds: 4), onTimeout: () {}),
      );

      await Future<void>.delayed(AppConstants.splashDuration);
      if (!mounted) return;

      _navigateNext(settings.pinEnabled || settings.biometricEnabled);
    } catch (e, st) {
      debugPrint('Splash boot failed: $e\n$st');
      if (!mounted) return;
      _navigateNext(false);
    }
  }

  void _navigateNext(bool needsLock) {
    if (needsLock) {
      context.go('/lock');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUnlockedProvider.notifier).state = true;
      final pending = ref.read(pendingRouteProvider);
      if (pending != null && pending.isNotEmpty) {
        ref.read(pendingRouteProvider.notifier).state = null;
        context.go(pending);
        return;
      }
      final settings = ref.read(settingsRepositoryProvider).get();
      if (!settings.onboardingComplete) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(visualStyleProvider);
    final palette = AppColors.palette(style);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.heroGradient,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/branding/pocketflow_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
