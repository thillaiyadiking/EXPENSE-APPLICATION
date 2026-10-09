import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/icon_utils.dart';
import '../../providers/providers.dart';
import '../../widgets/balance_hero_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/theme_mode_button.dart';
import '../../widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final categories = ref.watch(categoryMapProvider);
    final currency = ref.watch(currencyCodeProvider);
    final month = ref.watch(selectedMonthProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 800 ? 900.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketFlow'),
        actions: [
          const MonthNavBarActions(),
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dash) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(transactionsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    BalanceHeroCard(
                      balance: dash.balance,
                      income: dash.totalIncome,
                      expense: dash.totalExpense,
                      budgetRemaining: dash.budgetRemaining,
                      budgetProgress: dash.budgetProgress,
                      currencyCode: currency,
                      monthLabel: DateFormatters.monthYear(month),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.remove_circle_outline,
                            label: 'Expense',
                            onTap: () => context.push('/add?type=expense'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle_outline,
                            label: 'Income',
                            onTap: () => context.push('/add?type=income'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.replay_rounded,
                            label: 'Refund',
                            onTap: () => context.push('/add?type=refund'),
                          ),
                        ),
                      ],
                    ),
                    if (dash.categoryBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Category breakdown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: dash.categoryBreakdown.entries
                              .toList()
                              .take(5)
                              .map((e) {
                            final cat = categories[e.key];
                            final total = dash.totalExpense;
                            final pct = total <= 0 ? 0.0 : e.value / total;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    iconFromCode(
                                      cat?.iconCode ??
                                          Icons.category.codePoint,
                                    ),
                                    color: Color(cat?.colorValue ?? 0xFF64748B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(cat?.name ?? e.key)),
                                  Text(
                                    MoneyFormatter.format(
                                      e.value,
                                      currencyCode: currency,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${(pct * 100).toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Recent',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/search'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (dash.recentTransactions.isEmpty)
                      EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No transactions yet',
                        subtitle:
                            'Add your first expense in under two taps.',
                        actionLabel: 'Add expense',
                        onAction: () => context.push('/add'),
                      )
                    else
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            for (final tx in dash.recentTransactions)
                              TransactionTile(
                                transaction: tx,
                                category: categories[tx.categoryId],
                                currencyCode: currency,
                                onTap: () =>
                                    context.push('/transaction/${tx.id}'),
                                onEdit: () => context.push('/edit/${tx.id}'),
                                onDelete: () => ref
                                    .read(transactionControllerProvider)
                                    .delete(tx.id),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
