import '../core/utils/formatters.dart';
import '../domain/entities/analytics_entities.dart';
import '../models/models.dart';

class AnalyticsService {
  List<TransactionModel> filterTransactions(
    List<TransactionModel> all,
    TransactionFilter filter,
  ) {
    var result = all.where((tx) {
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        if (!tx.note.toLowerCase().contains(q) &&
            !tx.amount.toString().contains(q) &&
            !tx.tags.any((t) => t.toLowerCase().contains(q))) {
          return false;
        }
      }
      if (filter.categoryIds.isNotEmpty &&
          !filter.categoryIds.contains(tx.categoryId)) {
        return false;
      }
      if (filter.accountIds.isNotEmpty &&
          !filter.accountIds.contains(tx.accountId)) {
        return false;
      }
      if (filter.types.isNotEmpty && !filter.types.contains(tx.type)) {
        return false;
      }
      if (filter.tags.isNotEmpty &&
          !filter.tags.any((t) => tx.tags.contains(t))) {
        return false;
      }
      if (filter.startDate != null &&
          tx.date.isBefore(DateTime(
            filter.startDate!.year,
            filter.startDate!.month,
            filter.startDate!.day,
          ))) {
        return false;
      }
      if (filter.endDate != null) {
        final end = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
          23,
          59,
          59,
        );
        if (tx.date.isAfter(end)) return false;
      }
      if (filter.minAmount != null && tx.amount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      int cmp;
      switch (filter.sortField) {
        case SortField.date:
          cmp = a.date.compareTo(b.date);
        case SortField.amount:
          cmp = a.amount.compareTo(b.amount);
        case SortField.note:
          cmp = a.note.compareTo(b.note);
      }
      return filter.sortOrder == SortOrder.ascending ? cmp : -cmp;
    });

    return result;
  }

  DashboardSummary buildDashboard({
    required List<TransactionModel> transactions,
    required double budgetAmount,
    DateTime? month,
    int recentLimit = 8,
  }) {
    final start = PeriodHelper.startOfMonth(month);
    final end = PeriodHelper.endOfMonth(month);
    final monthly = transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();

    double income = 0;
    double expense = 0;
    final breakdown = <String, double>{};

    for (final tx in monthly) {
      if (tx.isIncome || tx.isRefund) {
        income += tx.amount.abs();
      } else {
        expense += tx.amount.abs();
        breakdown[tx.categoryId] =
            (breakdown[tx.categoryId] ?? 0) + tx.amount.abs();
      }
    }

    final allBalance =
        transactions.fold<double>(0, (sum, t) => sum + t.signedAmount);
    final remaining = budgetAmount - expense;
    final progress = budgetAmount <= 0 ? 0.0 : expense / budgetAmount;

    final recent = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSummary(
      balance: allBalance,
      totalIncome: income,
      totalExpense: expense,
      budgetAmount: budgetAmount,
      budgetRemaining: remaining,
      budgetProgress: progress,
      categoryBreakdown: breakdown,
      recentTransactions: recent.take(recentLimit).toList(),
    );
  }

  List<CategorySpend> topCategories(
    Map<String, double> breakdown, {
    int limit = 5,
  }) {
    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) {
      return CategorySpend(
        categoryId: e.key,
        amount: e.value,
        percentage: total <= 0 ? 0 : e.value / total,
      );
    }).toList();
  }

  List<MonthlyTrendPoint> monthlyTrends(
    List<TransactionModel> transactions, {
    int months = 6,
  }) {
    return PeriodHelper.lastNMonths(months).map((month) {
      final start = PeriodHelper.startOfMonth(month);
      final end = PeriodHelper.endOfMonth(month);
      double income = 0;
      double expense = 0;
      for (final tx in transactions) {
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) continue;
        if (tx.isIncome || tx.isRefund) {
          income += tx.amount.abs();
        } else {
          expense += tx.amount.abs();
        }
      }
      return MonthlyTrendPoint(month: month, income: income, expense: expense);
    }).toList();
  }

  List<DailySpendPoint> weeklySpending(List<TransactionModel> transactions) {
    final start = PeriodHelper.startOfWeek();
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final amount = transactions
          .where(
            (t) =>
                t.isExpense &&
                !t.date.isBefore(dayStart) &&
                t.date.isBefore(dayEnd),
          )
          .fold<double>(0, (s, t) => s + t.amount.abs());
      return DailySpendPoint(date: dayStart, amount: amount);
    });
  }

  Map<String, double> categoryPie(
    List<TransactionModel> transactions, {
    DateTime? month,
  }) {
    final start = PeriodHelper.startOfMonth(month);
    final end = PeriodHelper.endOfMonth(month);
    final map = <String, double>{};
    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      if (tx.date.isBefore(start) || tx.date.isAfter(end)) continue;
      map[tx.categoryId] = (map[tx.categoryId] ?? 0) + tx.amount.abs();
    }
    return map;
  }

  ({double currentExpense, double previousExpense}) spendingComparison(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final current = buildDashboard(
      transactions: transactions,
      budgetAmount: 1,
      month: now,
    ).totalExpense;
    final previous = buildDashboard(
      transactions: transactions,
      budgetAmount: 1,
      month: DateTime(now.year, now.month - 1),
    ).totalExpense;
    return (currentExpense: current, previousExpense: previous);
  }
}
