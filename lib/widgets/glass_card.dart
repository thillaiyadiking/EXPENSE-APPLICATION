import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final isRich =
        Theme.of(context).extension<PocketFlowThemeExt>()?.isRich ?? false;
    final radius = isRich ? borderRadius + 2 : borderRadius;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.withOpacity(Colors.white, isRich ? 0.12 : 0.08),
                      AppColors.withOpacity(Colors.white, isRich ? 0.05 : 0.03),
                    ]
                  : [
                      Colors.white.withValues(alpha: isRich ? 0.96 : 0.92),
                      Colors.white.withValues(alpha: isRich ? 0.82 : 0.75),
                    ],
            ),
        border: Border.all(
          color: isDark
              ? AppColors.withOpacity(Colors.white, isRich ? 0.16 : 0.1)
              : AppColors.withOpacity(scheme.primary, isRich ? 0.18 : 0.08),
          width: isRich ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(
              isRich ? scheme.primary : Colors.black,
              isDark
                  ? (isRich ? 0.25 : 0.3)
                  : (isRich ? 0.12 : 0.06),
            ),
            blurRadius: isRich ? 32 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
