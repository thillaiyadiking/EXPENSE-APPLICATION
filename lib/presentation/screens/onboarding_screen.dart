import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../services/home_widget_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});

  /// When true, finishing returns via pop/go without requiring incomplete flag.
  final bool replay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  int _page = 0;
  bool _pinning = false;
  bool _finishing = false;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      title: 'Welcome to PocketFlow',
      body:
          'A premium offline expense tracker. Your money stays on this device — no account required.',
      icon: Icons.water_drop_rounded,
    ),
    _OnboardPage(
      title: 'Home & quick add',
      body:
          'See balance, budget progress, and recent activity. Use Expense / Income / Refund or the + button to add in seconds.',
      icon: Icons.home_rounded,
    ),
    _OnboardPage(
      title: 'Analytics',
      body:
          'Spot trends with weekly spend, category breakdowns, and month-over-month comparisons.',
      icon: Icons.insights_rounded,
    ),
    _OnboardPage(
      title: 'Budgets that keep you honest',
      body:
          'Set a monthly limit and optional category caps. PocketFlow warns you as you approach or exceed them.',
      icon: Icons.pie_chart_rounded,
    ),
    _OnboardPage(
      title: 'Money Glance widget',
      body:
          'Pin a weather-style home-screen card for balance, today & month spend, and budget — tap + to add an expense.',
      icon: Icons.widgets_rounded,
      showPin: true,
    ),
    _OnboardPage(
      title: 'Stay secure',
      body:
          'Optional PIN and biometric lock protect your data. Turn them on anytime in Settings.',
      icon: Icons.fingerprint_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(homeWidgetPinnedProvider);
    }
  }

  Future<void> _complete() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final settings = ref.read(settingsRepositoryProvider).get();
    if (!settings.onboardingComplete) {
      await ref.read(settingsControllerProvider).update(
            settings.copyWith(onboardingComplete: true),
          );
    }

    if (!mounted) return;

    if (widget.replay) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/settings');
      }
      return;
    }

    ref.read(appUnlockedProvider.notifier).state = true;
    final pending = ref.read(pendingRouteProvider);
    if (pending != null && pending.isNotEmpty) {
      ref.read(pendingRouteProvider.notifier).state = null;
      context.go(pending);
    } else {
      context.go('/home');
    }
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pinWidget() async {
    final pinned = ref.read(homeWidgetPinnedProvider).valueOrNull ?? false;
    if (pinned) return;

    setState(() => _pinning = true);
    final result = await ref.read(homeWidgetServiceProvider).requestPinWidget();
    if (!mounted) return;
    setState(() => _pinning = false);
    ref.invalidate(homeWidgetPinnedProvider);

    final message = switch (result) {
      PinWidgetResult.prompted =>
        'Follow the system prompt to place PocketFlow on your home screen.',
      PinWidgetResult.alreadyPinned =>
        'Money Glance is already on your home screen.',
      PinWidgetResult.unsupported =>
        'Pinning isn’t supported here. Long-press home → Widgets → PocketFlow.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(visualStyleProvider);
    final palette = AppColors.palette(style);
    final isLast = _page >= _pages.length - 1;
    final current = _pages[_page];
    final pinned = ref.watch(homeWidgetPinnedProvider).valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  if (widget.replay)
                    IconButton(
                      onPressed: _finishing ? null : () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishing ? null : _complete,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OnboardVisual(
                          icon: page.icon,
                          palette: palette,
                          scheme: scheme,
                          pageIndex: index,
                        )
                            .animate(key: ValueKey('viz-$index'))
                            .fadeIn(duration: 380.ms)
                            .scale(
                              begin: const Offset(0.88, 0.88),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                              duration: 480.ms,
                            ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        )
                            .animate()
                            .fadeIn(delay: 80.ms)
                            .slideY(begin: 0.12, end: 0),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                        ).animate().fadeIn(delay: 140.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (current.showPin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pinned || _pinning || _finishing
                            ? null
                            : _pinWidget,
                        icon: _pinning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                pinned
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.add_to_home_screen_rounded,
                              ),
                        label: Text(
                          _pinning
                              ? 'Opening…'
                              : pinned
                                  ? 'Already on home screen'
                                  : 'Add to home screen',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _finishing ? null : _next,
                      child: Text(isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                  if (!widget.replay) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.title,
    required this.body,
    required this.icon,
    this.showPin = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool showPin;
}

class _OnboardVisual extends StatelessWidget {
  const _OnboardVisual({
    required this.icon,
    required this.palette,
    required this.scheme,
    required this.pageIndex,
  });

  final IconData icon;
  final BrandPalette palette;
  final ColorScheme scheme;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, size: 64, color: Colors.white)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: pageIndex.isEven ? -5 : 5,
            duration: 1400.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
