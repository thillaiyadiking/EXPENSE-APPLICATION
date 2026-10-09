import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_settings_model.dart';
import 'app_colors.dart';

/// Marks ThemeData as Rich style so widgets can amplify glass/glow.
class PocketFlowThemeExt extends ThemeExtension<PocketFlowThemeExt> {
  const PocketFlowThemeExt({
    required this.style,
    required this.heroGradient,
  });

  final AppVisualStyle style;
  final List<Color> heroGradient;

  bool get isRich => style == AppVisualStyle.rich;

  @override
  PocketFlowThemeExt copyWith({
    AppVisualStyle? style,
    List<Color>? heroGradient,
  }) {
    return PocketFlowThemeExt(
      style: style ?? this.style,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  PocketFlowThemeExt lerp(ThemeExtension<PocketFlowThemeExt>? other, double t) {
    if (other is! PocketFlowThemeExt) return this;
    return t < 0.5 ? this : other;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light([AppVisualStyle style = AppVisualStyle.classic]) {
    final palette = AppColors.palette(style);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.light,
      surface: palette.lightSurface,
    );

    return _build(scheme, Brightness.light, palette, style);
  }

  static ThemeData dark([AppVisualStyle style = AppVisualStyle.classic]) {
    final palette = AppColors.palette(style);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.dark,
      surface: palette.darkSurface,
    );

    return _build(scheme, Brightness.dark, palette, style);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Brightness brightness,
    BrandPalette palette,
    AppVisualStyle style,
  ) {
    final isDark = brightness == Brightness.dark;
    final isRich = style == AppVisualStyle.rich;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    final cardRadius = isRich ? 24.0 : 20.0;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        primary: isRich
            ? (isDark ? palette.brandLight : palette.brand)
            : scheme.primary,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        PocketFlowThemeExt(
          style: style,
          heroGradient: palette.heroGradient,
        ),
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? palette.darkCard : palette.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isRich ? palette.brand : scheme.primary,
        foregroundColor: isRich ? const Color(0xFF0B1220) : scheme.onPrimary,
        elevation: isRich ? 6 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isRich ? 20 : 18),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? palette.darkCard : palette.lightCard,
        indicatorColor: AppColors.withOpacity(
          isRich ? palette.brand : scheme.primary,
          0.15,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.withOpacity(Colors.white, 0.06)
            : AppColors.withOpacity(scheme.primary, 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isRich ? palette.brand : scheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.withOpacity(scheme.onSurface, 0.08),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
