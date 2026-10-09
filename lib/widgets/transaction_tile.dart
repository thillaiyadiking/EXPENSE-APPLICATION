import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/icon_utils.dart';
import '../models/models.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currencyCode,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final TransactionModel transaction;
  final CategoryModel? category;
  final String currencyCode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  Color get _amountColor {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.refund:
        return AppColors.refund;
      case TransactionType.expense:
        return AppColors.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = Color(category?.colorValue ?? 0xFF64748B);
    final icon = iconFromCode(
      category?.iconCode ?? Icons.category_rounded.codePoint,
    );

    final child = ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Hero(
        tag: 'tx-icon-${transaction.id}',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: catColor),
        ),
      ),
      title: Text(
        category?.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (transaction.note.isNotEmpty) transaction.note,
          DateFormatters.relative(transaction.date),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.55),
          fontSize: 13,
        ),
      ),
      trailing: Text(
        MoneyFormatter.format(
          transaction.signedAmount,
          currencyCode: currencyCode,
          showSign: true,
        ),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: _amountColor,
          fontSize: 15,
        ),
      ),
    );

    if (onDelete == null && onEdit == null) return child;

    return Dismissible(
      key: ValueKey(transaction.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.income.withValues(alpha: 0.15),
        child: const Icon(Icons.edit_rounded, color: AppColors.income),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.expense.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) onDelete?.call();
        return confirmed ?? false;
      },
      child: child,
    );
  }
}
