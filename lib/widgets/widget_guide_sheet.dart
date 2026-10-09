import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/providers.dart';
import '../services/home_widget_service.dart';

/// Animated coach sheet that teaches the Money Glance home widget.
Future<void> showWidgetGuideSheet(
  BuildContext context, {
  bool markComplete = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WidgetGuideSheet(markComplete: markComplete),
  );
}

class WidgetGuideSheet extends ConsumerStatefulWidget {
  const WidgetGuideSheet({super.key, this.markComplete = true});

  final bool markComplete;

  @override
  ConsumerState<WidgetGuideSheet> createState() => _WidgetGuideSheetState();
}

class _WidgetGuideSheetState extends ConsumerState<WidgetGuideSheet>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _page = 0;
  bool _pinning = false;

  static const _steps = [
    (
      title: 'Your money at a glance',
      body:
          'Like a weather card on your home screen — see balance, today\'s spend, and budget without opening the app.',
      icon: Icons.widgets_rounded,
    ),
    (
      title: 'Add PocketFlow widget',
      body:
          'Long-press your home screen → Widgets → PocketFlow. Or tap the button below to pin it (supported on many Android phones).',
      icon: Icons.add_to_home_screen_rounded,
    ),
    (
      title: 'Tap + to add expense',
      body:
          'Resize small or medium. Tap the card to open Home, or tap + to jump straight into Add Expense.',
      icon: Icons.add_circle_rounded,
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(homeWidgetPinnedProvider);
    }
  }

  Future<void> _finish() async {
    if (widget.markComplete) {
      final settings = ref.read(settingsRepositoryProvider).get();
      if (!settings.onboardingComplete) {
        await ref.read(settingsControllerProvider).update(
              settings.copyWith(onboardingComplete: true),
            );
      }
    }
    if (mounted) Navigator.of(context).pop();
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
        'Pinning isn\'t supported here. Long-press home → Widgets → PocketFlow.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(visualStyleProvider);
    final palette = AppColors.palette(style);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    children: [
                      _GuideVisual(
                        page: index,
                        palette: palette,
                        scheme: scheme,
                      )
                          .animate(key: ValueKey('viz-$index'))
                          .fadeIn(duration: 350.ms)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                            duration: 450.ms,
                          ),
                      const SizedBox(height: 20),
                      Icon(step.icon, color: scheme.primary, size: 28)
                          .animate()
                          .fadeIn(delay: 80.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 10),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        step.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ).animate().fadeIn(delay: 160.ms),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_page == 1) ...[
              Builder(
                builder: (context) {
                  final pinned =
                      ref.watch(homeWidgetPinnedProvider).valueOrNull ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: pinned || _pinning ? null : _pinWidget,
                      icon: _pinning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page >= _steps.length - 1 ? 'Got it' : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideVisual extends StatelessWidget {
  const _GuideVisual({
    required this.page,
    required this.palette,
    required this.scheme,
  });

  final int page;
  final BrandPalette palette;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: switch (page) {
        0 => _FakeWidgetPreview(palette: palette)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut),
        1 => Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 120,
                color: scheme.outlineVariant,
              ),
              Positioned(
                bottom: 28,
                child: _FakeWidgetPreview(palette: palette, compact: true)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 1200.ms,
                    )
                    .fadeIn(),
              ),
              Positioned(
                top: 18,
                right: 48,
                child: Icon(
                  Icons.touch_app_rounded,
                  color: scheme.primary,
                  size: 36,
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(begin: const Offset(8, -8), end: Offset.zero, duration: 900.ms),
              ),
            ],
          ),
        _ => Stack(
            alignment: Alignment.center,
            children: [
              _FakeWidgetPreview(palette: palette),
              Positioned(
                right: 36,
                top: 28,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70),
                  ),
                  child: const Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.18, 1.18),
                      duration: 700.ms,
                    ),
              ),
            ],
          ),
      },
    );
  }
}

class _FakeWidgetPreview extends StatelessWidget {
  const _FakeWidgetPreview({
    required this.palette,
    this.compact = false,
  });

  final BrandPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 180 : 260,
      height: compact ? 72 : 120,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brand, palette.brandDark],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PocketFlow',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            '₹12,480',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!compact) ...[
            const Spacer(),
            Text(
              'Today ₹320  ·  Month ₹4,120',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
