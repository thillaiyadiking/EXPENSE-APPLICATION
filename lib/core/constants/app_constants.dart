class AppConstants {
  AppConstants._();

  static const String appName = 'PocketFlow';
  static const String appTagline = 'Money, simply flowing';
  static const String hiveBoxTransactions = 'transactions';
  static const String hiveBoxCategories = 'categories';
  static const String hiveBoxBudgets = 'budgets';
  static const String hiveBoxAccounts = 'accounts';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxTags = 'tags';
  static const String hiveBoxBudgetHistory = 'budget_history';

  static const String defaultCurrencyCode = 'USD';
  static const String defaultCurrencySymbol = '\$';

  static const Duration splashDuration = Duration(milliseconds: 1800);
  static const int recentTransactionsLimit = 8;
  static const double defaultMonthlyBudget = 2000;

  /// Type this key in Settings → Clear all data to confirm wipe.
  static const String dataWipeSecurityKey = 'CLEAR';
}

class HiveTypeIds {
  HiveTypeIds._();

  static const int transaction = 0;
  static const int category = 1;
  static const int budget = 2;
  static const int account = 3;
  static const int appSettings = 4;
  static const int tag = 5;
  static const int budgetHistory = 6;
  static const int transactionType = 7;
  static const int accountType = 8;
  static const int recurrenceRule = 9;
  static const int themeMode = 10;
}
