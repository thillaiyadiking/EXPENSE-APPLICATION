import 'package:flutter/material.dart';

import '../core/utils/icon_utils.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final int iconCode;
  final int colorValue;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap?.call(),
      avatar: Icon(
        iconFromCode(iconCode),
        size: 18,
        color: selected ? Colors.white : color,
      ),
      label: Text(name),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.large = false,
    this.color,
  });

  final double amount;
  final String currencyCode;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Imported via formatters in callers; keep simple
    return Text(
      amount.toStringAsFixed(2),
      style: TextStyle(
        fontSize: large ? 40 : 16,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: large ? -1 : 0,
      ),
    );
  }
}
