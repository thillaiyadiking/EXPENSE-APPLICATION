import '../../models/transaction_model.dart';

enum SortField { date, amount, note }
enum SortOrder { ascending, descending }

class TransactionFilter {
  const TransactionFilter({
    this.query = '',
    this.categoryIds = const {},
    this.accountIds = const {},
    this.types = const {},
    this.tags = const {},
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortField = SortField.date,
    this.sortOrder = SortOrder.descending,
  });

  final String query;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final Set<TransactionType> types;
  final Set<String> tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final SortField sortField;
  final SortOrder sortOrder;

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      categoryIds.isNotEmpty ||
      accountIds.isNotEmpty ||
      types.isNotEmpty ||
      tags.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilter copyWith({
    String? query,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    Set<TransactionType>? types,
    Set<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    SortField? sortField,
    SortOrder? sortOrder,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      types: types ?? this.types,
      tags: tags ?? this.tags,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static const empty = TransactionFilter();
}

class DashboardSummary {
  const DashboardSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.budgetAmount,
    required this.budgetRemaining,
    required this.budgetProgress,
    required this.categoryBreakdown,
    required this.recentTransactions,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final double budgetAmount;
  final double budgetRemaining;
  final double budgetProgress;
  final Map<String, double> categoryBreakdown;
  final List<TransactionModel> recentTransactions;

  bool get isOverBudget => budgetRemaining < 0;
}

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final double amount;
  final double percentage;
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

class DailySpendPoint {
  const DailySpendPoint({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final double amount;
}
