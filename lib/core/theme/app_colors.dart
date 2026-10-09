import 'package:flutter/material.dart';

import '../../models/app_settings_model.dart';

class BrandPalette {
  const BrandPalette({
    required this.seed,
    required this.brand,
    required this.brandLight,
    required this.brandDark,
    required this.lightSurface,
    required this.lightCard,
    required this.darkSurface,
    required this.darkCard,
    required this.heroGradient,
  });

  final Color seed;
  final Color brand;
  final Color brandLight;
  final Color brandDark;
  final Color lightSurface;
  final Color lightCard;
  final Color darkSurface;
  final Color darkCard;
  final List<Color> heroGradient;
}

class AppColors {
  AppColors._();

  // Classic — deep teal / emerald fintech
  static const BrandPalette classic = BrandPalette(
    seed: Color(0xFF0D9488),
    brand: Color(0xFF0F766E),
    brandLight: Color(0xFF14B8A6),
    brandDark: Color(0xFF134E4A),
    lightSurface: Color(0xFFF8FAFC),
    lightCard: Color(0xFFFFFFFF),
    darkSurface: Color(0xFF0F172A),
    darkCard: Color(0xFF1E293B),
    heroGradient: [
      Color(0xFF134E4A),
      Color(0xFF0F766E),
      Color(0xFF14B8A6),
    ],
  );

  // Rich — navy / obsidian + warm gold
  static const BrandPalette rich = BrandPalette(
    seed: Color(0xFFC9A227),
    brand: Color(0xFFB8860B),
    brandLight: Color(0xFFE8C547),
    brandDark: Color(0xFF0B1220),
    lightSurface: Color(0xFFF7F4EF),
    lightCard: Color(0xFFFFFCF8),
    darkSurface: Color(0xFF070B14),
    darkCard: Color(0xFF121A2A),
    heroGradient: [
      Color(0xFF070B14),
      Color(0xFF1A2740),
      Color(0xFFB8860B),
    ],
  );

  static BrandPalette palette(AppVisualStyle style) =>
      style == AppVisualStyle.rich ? rich : classic;

  // Legacy aliases (Classic) for screens that still reference static tokens
  static const Color seed = Color(0xFF0D9488);
  static const Color brand = Color(0xFF0F766E);
  static const Color brandLight = Color(0xFF14B8A6);
  static const Color brandDark = Color(0xFF134E4A);

  static const Color income = Color(0xFF059669);
  static const Color expense = Color(0xFFDC2626);
  static const Color refund = Color(0xFF2563EB);
  static const Color warning = Color(0xFFD97706);
  static const Color overspend = Color(0xFFEF4444);

  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);

  static const List<Color> categoryPalette = [
    Color(0xFFF97316),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF84CC16),
  ];

  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  /// Theme extension key for richer glass treatment.
  static const String richGlassFlag = 'pocketflow_rich_glass';
}
