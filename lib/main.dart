import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/hive_database.dart';
import 'models/app_settings_model.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await HiveDatabase.init();

  runApp(const ProviderScope(child: PocketFlowApp()));
}

class PocketFlowApp extends ConsumerStatefulWidget {
  const PocketFlowApp({super.key});

  @override
  ConsumerState<PocketFlowApp> createState() => _PocketFlowAppState();
}

class _PocketFlowAppState extends ConsumerState<PocketFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initExternalLaunchers();
    });
  }

  void _initExternalLaunchers() {
    void handle(String route) => requestExternalRoute(ref, route);
    ref.read(homeWidgetServiceProvider).init(onRouteRequested: handle);
    ref.read(appShortcutsServiceProvider).init(onRouteRequested: handle);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only lock when fully backgrounded — inactive fires during system dialogs.
    if (state == AppLifecycleState.paused) {
      // Defer past the current frame to avoid Riverpod rebuild races.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lockIfNeeded();
      });
    }
  }

  void _lockIfNeeded() {
    try {
      final settings = ref.read(settingsRepositoryProvider).get();
      final needsLock = settings.pinEnabled || settings.biometricEnabled;
      if (!needsLock) return;
      if (!ref.read(appUnlockedProvider)) return;

      ref.read(authServiceProvider).lock();
      ref.read(appUnlockedProvider.notifier).state = false;
    } catch (_) {
      // Ignore lock errors during teardown / mid-rebuild.
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final visualStyle = ref.watch(visualStyleProvider);

    return MaterialApp.router(
      title: 'PocketFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(visualStyle),
      darkTheme: AppTheme.dark(visualStyle),
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
