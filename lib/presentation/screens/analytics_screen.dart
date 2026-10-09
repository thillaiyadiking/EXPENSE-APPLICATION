import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/analytics_entities.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/theme_mode_button.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyCodeProvider);
    final categories = ref.watch(categoryMapProvider);
    final pieAsync = ref.watch(categoryPieProvider);
    final trendsAsync = ref.watch(monthlyTrendsProvider);
    final weeklyAsync = ref.watch(weeklySpendingProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 800 ? 900.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: const [
          MonthNavBarActions(),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              txsAsync.when(
                loading: () => const _AnalyticsSkeleton(),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (txs) {
                  final comparison = analytics.spendingComparison(txs);
                  return _ComparisonCard(
                    current: comparison.currentExpense,
                    previous: comparison.previousExpense,
                    currencyCode: currency,
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Spending by category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              pieAsync.when(
                loading: () => const SkeletonLoader(height: 220, borderRadius: 24),
                error: (e, _) => Text('Error: $e'),
                data: (pieData) {
                  if (pieData.isEmpty) {
                    return const GlassCard(
                      child: EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No spending data',
                        subtitle: 'Add expenses to see category breakdown.',
                      ),
                    );
                  }
                  final top = analytics.topCategories(pieData, limit: 5);
                  final total = pieData.values.fold<double>(0, (a, b) => a + b);
                  final sections = pieData.entries.map((e) {
                    final cat = categories[e.key];
                    final color = Color(cat?.colorValue ?? 0xFF64748B);
                    return PieChartSectionData(
                      value: e.value,
                      title: total <= 0
                          ? ''
                          : '${((e.value / total) * 100).toStringAsFixed(0)}%',
                      color: color,
                      radius: 52,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).toList();

                  return GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 44,
                              sections: sections,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...top.map((item) {
                          final cat = categories[item.categoryId];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      cat?.colorValue ?? 0xFF64748B,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(cat?.name ?? 'Other')),
                                Text(
                                  MoneyFormatter.format(
                                    item.amount,
                                    currencyCode: currency,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${(item.percentage * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Income vs expense',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              trendsAsync.when(
                loading: () => const SkeletonLoader(height: 220, borderRadius: 24),
                error: (e, _) => Text('Error: $e'),
                data: (trends) => GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                  child: SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxTrendY(trends),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxTrendY(trends) / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outline.withValues(alpha: 0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  MoneyFormatter.format(
                                    value,
                                    currencyCode: currency,
                                    compact: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= trends.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormatters.short(trends[i].month),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(trends.length, (i) {
                          final point = trends[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: point.income,
                                color: AppColors.income,
                                width: 8,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              BarChartRodData(
                                toY: point.expense,
                                color: AppColors.expense,
                                width: 8,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'This week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              weeklyAsync.when(
                loading: () => const SkeletonLoader(height: 200, borderRadius: 24),
                error: (e, _) => Text('Error: $e'),
                data: (week) => GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: _maxWeeklyY(week),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outline.withValues(alpha: 0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= week.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormatters.short(week[i].date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(week.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: week[i].amount,
                                color: AppColors.brand,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Top categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              pieAsync.when(
                loading: () => const SkeletonLoader(height: 120, borderRadius: 24),
                error: (e, _) => const SizedBox.shrink(),
                data: (pieData) {
                  if (pieData.isEmpty) return const SizedBox.shrink();
                  final top = ref
                      .read(analyticsServiceProvider)
                      .topCategories(pieData, limit: 5);
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < top.length; i++)
                          _TopCategoryRow(
                            rank: i + 1,
                            name: categories[top[i].categoryId]?.name ?? 'Other',
                            amount: top[i].amount,
                            percentage: top[i].percentage,
                            color: Color(
                              categories[top[i].categoryId]?.colorValue ??
                                  0xFF64748B,
                            ),
                            currencyCode: currency,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _maxTrendY(List<MonthlyTrendPoint> trends) {
    var max = 0.0;
    for (final t in trends) {
      if (t.income > max) max = t.income;
      if (t.expense > max) max = t.expense;
    }
    return max <= 0 ? 100 : max * 1.2;
  }

  double _maxWeeklyY(List<DailySpendPoint> week) {
    var max = week.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    return max <= 0 ? 100 : max * 1.2;
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.current,
    required this.previous,
    required this.currencyCode,
  });

  final double current;
  final double previous;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final pctChange = previous <= 0 ? 0.0 : (diff / previous) * 100;
    final isUp = diff > 0;

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.brand.withValues(alpha: 0.12),
          AppColors.brandLight.withValues(alpha: 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This month vs last',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'This month',
                  value: MoneyFormatter.format(current, currencyCode: currencyCode),
                ),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'Last month',
                  value: MoneyFormatter.format(previous, currencyCode: currencyCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 18,
                color: isUp ? AppColors.expense : AppColors.income,
              ),
              const SizedBox(width: 6),
              Text(
                '${isUp ? '+' : ''}${MoneyFormatter.format(diff.abs(), currencyCode: currencyCode)} '
                '(${pctChange.abs().toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUp ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  const _TopCategoryRow({
    required this.rank,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.currencyCode,
  });

  final int rank;
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0, 1),
                    minHeight: 4,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            MoneyFormatter.format(amount, currencyCode: currencyCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonLoader(height: 120, borderRadius: 24),
        SizedBox(height: 20),
        SkeletonLoader(height: 220, borderRadius: 24),
      ],
    );
  }
}
