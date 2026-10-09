import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings_model.dart';
import '../providers/providers.dart';

/// Quick theme control for app bars (System / Light / Dark).
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  IconData _iconFor(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_rounded,
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
    };
  }

  String _labelFor(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return PopupMenuButton<AppThemeMode>(
      tooltip: 'Theme',
      initialValue: mode,
      onSelected: (value) {
        ref.read(settingsControllerProvider).setTheme(value);
      },
      itemBuilder: (context) => [
        for (final m in AppThemeMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(_iconFor(m), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_labelFor(m))),
                if (m == mode)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(_iconFor(mode)),
      ),
    );
  }
}

/// Quick appearance control for app bars (Classic / Rich).
class AppearanceStyleButton extends ConsumerWidget {
  const AppearanceStyleButton({super.key});

  static const _classicColors = [
    Color(0xFF134E4A),
    Color(0xFF0F766E),
    Color(0xFF14B8A6),
  ];
  static const _richColors = [
    Color(0xFF070B14),
    Color(0xFF1A2740),
    Color(0xFFB8860B),
  ];

  List<Color> _colorsFor(AppVisualStyle style) {
    return style == AppVisualStyle.rich ? _richColors : _classicColors;
  }

  String _labelFor(AppVisualStyle style) {
    return switch (style) {
      AppVisualStyle.classic => 'Classic',
      AppVisualStyle.rich => 'Rich',
    };
  }

  Widget _swatch(List<Color> colors) {
    return SizedBox(
      width: 28,
      height: 14,
      child: Row(
        children: [
          for (var i = 0; i < colors.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.horizontal(
                    left: i == 0 ? const Radius.circular(4) : Radius.zero,
                    right: i == colors.length - 1
                        ? const Radius.circular(4)
                        : Radius.zero,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(visualStyleProvider);
    final iconColor = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<AppVisualStyle>(
      tooltip: 'Appearance',
      initialValue: style,
      onSelected: (value) {
        ref.read(settingsControllerProvider).setVisualStyle(value);
      },
      itemBuilder: (context) => [
        for (final s in AppVisualStyle.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                _swatch(_colorsFor(s)),
                const SizedBox(width: 12),
                Expanded(child: Text(_labelFor(s))),
                if (s == style)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.palette_rounded,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Month prev / label / next used in app bars near theme & appearance controls.
class MonthNavBarActions extends ConsumerWidget {
  const MonthNavBarActions({
    super.key,
    this.showTheme = true,
    this.showAppearance = true,
  });

  final bool showTheme;
  final bool showAppearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous month',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1);
          },
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 88, maxWidth: 120),
          child: Text(
            _shortMonth(month),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1);
          },
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        if (showTheme) const ThemeModeButton(),
        if (showAppearance) const AppearanceStyleButton(),
      ],
    );
  }

  String _shortMonth(DateTime month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }
}
