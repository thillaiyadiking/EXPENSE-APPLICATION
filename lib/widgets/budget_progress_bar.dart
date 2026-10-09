import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.spent,
    required this.budget,
    required this.currencyCode,
    this.color,
  });

  final String label;
  final double spent;
  final double budget;
  final String currencyCode;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final progress = budget <= 0 ? 0.0 : spent / budget;
    final over = progress > 1;
    final barColor = color ?? (over ? AppColors.overspend : AppColors.brand);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${MoneyFormatter.format(spent, currencyCode: currencyCode)} / ${MoneyFormatter.format(budget, currencyCode: currencyCode)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: over ? AppColors.overspend : null,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: barColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        if (over) ...[
          const SizedBox(height: 4),
          Text(
            'Over by ${MoneyFormatter.format(spent - budget, currencyCode: currencyCode)}',
            style: const TextStyle(
              color: AppColors.overspend,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
