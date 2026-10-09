import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/safe_dispose.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/theme_mode_button.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetsProvider);
    final dashAsync = ref.watch(dashboardProvider);
    final month = ref.watch(selectedMonthProvider);
    final currency = ref.watch(currencyCodeProvider);
    final categories = ref.watch(categoryMapProvider);
    final budgetRepo = ref.watch(budgetRepositoryProvider);
    final categoryBudgets = budgetRepo.getCategoryBudgetsForMonth(month);
    final history = budgetRepo.getHistory();
    final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 800 ? 900.0 : double.infinity;

    final categorySpent = _categorySpending(txs, month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          const MonthNavBarActions(),
          IconButton(
            tooltip: 'Edit overall budget',
            onPressed: () => _showOverallBudgetDialog(context, ref),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dash) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormatters.monthYear(month),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brand,
                                  ),
                            ),
                            const Spacer(),
                            if (dash.isOverBudget)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.overspend.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: AppColors.overspend,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Over budget',
                                      style: TextStyle(
                                        color: AppColors.overspend,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BudgetProgressBar(
                          label: 'Overall budget',
                          spent: dash.totalExpense,
                          budget: dash.budgetAmount,
                          currencyCode: currency,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${MoneyFormatter.format(dash.budgetRemaining.abs(), currencyCode: currency)} '
                          '${dash.budgetRemaining >= 0 ? 'remaining' : 'over'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dash.isOverBudget
                                ? AppColors.overspend
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'Category budgets',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            _showCategoryBudgetDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (categoryBudgets.isEmpty)
                    EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'No category budgets',
                      subtitle: 'Set limits for individual spending categories.',
                      actionLabel: 'Add budget',
                      onAction: () => _showCategoryBudgetDialog(context, ref),
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (final budget in categoryBudgets)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: _CategoryBudgetTile(
                                budget: budget,
                                category: categories[budget.categoryId],
                                spent: categorySpent[budget.categoryId] ?? 0,
                                currencyCode: currency,
                                onEdit: () => _showCategoryBudgetDialog(
                                  context,
                                  ref,
                                  existing: budget,
                                ),
                                onDelete: () async {
                                  await budgetRepo.delete(budget.id);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Budget history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    const GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'History will appear after monthly budget cycles.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          for (final entry in history.take(12))
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: entry.wasOverspent
                                    ? AppColors.overspend.withValues(alpha: 0.12)
                                    : AppColors.income.withValues(alpha: 0.12),
                                child: Icon(
                                  entry.wasOverspent
                                      ? Icons.trending_up_rounded
                                      : Icons.check_rounded,
                                  color: entry.wasOverspent
                                      ? AppColors.overspend
                                      : AppColors.income,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                entry.categoryId == null
                                    ? 'Overall · ${DateFormatters.monthYear(entry.month)}'
                                    : '${categories[entry.categoryId]?.name ?? 'Category'} · ${DateFormatters.monthYear(entry.month)}',
                              ),
                              subtitle: Text(
                                '${MoneyFormatter.format(entry.spentAmount, currencyCode: currency)} of '
                                '${MoneyFormatter.format(entry.budgetAmount, currencyCode: currency)}',
                              ),
                              trailing: Text(
                                entry.wasOverspent ? 'Over' : 'On track',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: entry.wasOverspent
                                      ? AppColors.overspend
                                      : AppColors.income,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _categorySpending(
    List<TransactionModel> txs,
    DateTime month,
  ) {
    final start = PeriodHelper.startOfMonth(month);
    final end = PeriodHelper.endOfMonth(month);
    final map = <String, double>{};
    for (final tx in txs) {
      if (!tx.isExpense) continue;
      if (tx.date.isBefore(start) || tx.date.isAfter(end)) continue;
      map[tx.categoryId] = (map[tx.categoryId] ?? 0) + tx.amount.abs();
    }
    return map;
  }

  Future<void> _showOverallBudgetDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settings = ref.read(settingsRepositoryProvider).get();
    final controller = TextEditingController(
      text: settings.monthlyBudget.toStringAsFixed(0),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value >= 0) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount != null) {
      await ref.read(settingsControllerProvider).setMonthlyBudget(amount);
    }
    disposeAfterFrame([controller]);
  }

  Future<void> _showCategoryBudgetDialog(
    BuildContext context,
    WidgetRef ref, {
    BudgetModel? existing,
  }) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final expenseCategories =
        categories.where((c) => !c.isIncome).toList();
    if (expenseCategories.isEmpty) return;

    var selectedCategoryId =
        existing?.categoryId ?? expenseCategories.first.id;
    final amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add category budget' : 'Edit budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: expenseCategories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: existing == null
                    ? (v) {
                        if (v != null) setState(() => selectedCategoryId = v);
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Budget amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount != null && amount > 0) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final amount = double.parse(amountController.text.trim());
      final month = ref.read(selectedMonthProvider);
      await ref.read(budgetRepositoryProvider).upsert(
            BudgetModel(
              id: existing?.id ?? '',
              categoryId: selectedCategoryId,
              amount: amount,
              month: month,
              createdAt: existing?.createdAt ?? DateTime.now(),
            ),
          );
    }
    disposeAfterFrame([amountController]);
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  const _CategoryBudgetTile({
    required this.budget,
    required this.category,
    required this.spent,
    required this.currencyCode,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetModel budget;
  final CategoryModel? category;
  final double spent;
  final String currencyCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final over = spent > budget.amount;
    final catColor = Color(category?.colorValue ?? 0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              iconFromCode(
                category?.iconCode ?? Icons.category.codePoint,
              ),
              color: catColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category?.name ?? 'Category',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove budget?'),
                    content: const Text(
                      'This category will no longer have a spending limit.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) onDelete();
              },
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
        BudgetProgressBar(
          label: '',
          spent: spent,
          budget: budget.amount,
          currencyCode: currencyCode,
          color: over ? AppColors.overspend : catColor,
        ),
        if (over)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Overspent by ${MoneyFormatter.format(spent - budget.amount, currencyCode: currencyCode)}',
              style: const TextStyle(
                color: AppColors.overspend,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
