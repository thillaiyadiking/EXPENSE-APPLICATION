import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_database.dart';
import '../domain/entities/analytics_entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/analytics_service.dart';
import '../services/app_shortcuts_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../services/home_widget_service.dart';

// ── Repository providers ──────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => HiveTransactionRepository(),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => HiveCategoryRepository(),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => HiveBudgetRepository(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => HiveAccountRepository(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(),
);

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => HiveTagRepository(),
);

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(
    categoryRepo: ref.watch(categoryRepositoryProvider),
    accountRepo: ref.watch(accountRepositoryProvider),
    tagRepo: ref.watch(tagRepositoryProvider),
    transactionRepo: ref.watch(transactionRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
});

final analyticsServiceProvider = Provider((ref) => AnalyticsService());
final exportServiceProvider = Provider((ref) => ExportService());
final backupServiceProvider = Provider((ref) => BackupService());
final authServiceProvider = Provider((ref) => AuthService());
final notificationServiceProvider = Provider((ref) => NotificationService());
final homeWidgetServiceProvider = Provider((ref) => HomeWidgetService());
final appShortcutsServiceProvider = Provider((ref) => AppShortcutsService());

/// Whether Money Glance is already pinned on the Android home screen.
final homeWidgetPinnedProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(homeWidgetServiceProvider).isInstalled();
});

/// Deep-link / shortcut destination consumed after unlock or splash.
final pendingRouteProvider = StateProvider<String?>((ref) => null);

// ── Data streams ──────────────────────────────────────────────────────

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final accountsProvider = StreamProvider<List<AccountModel>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAll();
});

final settingsProvider = StreamProvider<AppSettingsModel>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final tagsProvider = Provider<List<TagModel>>((ref) {
  return ref.watch(tagRepositoryProvider).getAll();
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.empty);

final appUnlockedProvider = StateProvider<bool>((ref) => false);

// ── Derived providers ─────────────────────────────────────────────────

final categoryMapProvider = Provider<Map<String, CategoryModel>>((ref) {
  final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
  return {for (final c in cats) c.id: c};
});

final accountMapProvider = Provider<Map<String, AccountModel>>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  return {for (final a in accounts) a.id: a};
});

final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.currencyCode ?? 'USD';
});

final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.themeMode ??
      AppThemeMode.system;
});

final visualStyleProvider = Provider<AppVisualStyle>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.visualStyle ??
      AppVisualStyle.classic;
});

final dashboardProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final settingsAsync = ref.watch(settingsProvider);
  final month = ref.watch(selectedMonthProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return txsAsync.when(
    data: (txs) {
      final settings = settingsAsync.valueOrNull ?? AppSettingsModel();
      final overall = budgetRepo.getOverallForMonth(month);
      final budget = overall?.amount ?? settings.monthlyBudget;
      return AsyncValue.data(
        analytics.buildDashboard(
          transactions: txs,
          budgetAmount: budget,
          month: month,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return txsAsync.whenData(
    (txs) => analytics.filterTransactions(txs, filter),
  );
});

final monthlyTrendsProvider =
    Provider<AsyncValue<List<MonthlyTrendPoint>>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return txsAsync.whenData((txs) => analytics.monthlyTrends(txs));
});

final weeklySpendingProvider =
    Provider<AsyncValue<List<DailySpendPoint>>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return txsAsync.whenData((txs) => analytics.weeklySpending(txs));
});

final categoryPieProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final month = ref.watch(selectedMonthProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return txsAsync.whenData(
    (txs) => analytics.categoryPie(txs, month: month),
  );
});

// ── Controllers ───────────────────────────────────────────────────────

class TransactionController {
  TransactionController(this._ref);

  final Ref _ref;

  DateTime? _lastBudgetAlertAt;
  double? _lastAlertThreshold;

  TransactionRepository get _repo => _ref.read(transactionRepositoryProvider);

  Future<void> add(TransactionModel tx) async {
    await _repo.add(tx);
    await _afterMutation();
  }

  Future<void> update(TransactionModel tx) async {
    await _repo.update(tx);
    await _afterMutation();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _afterMutation(checkBudget: false);
  }

  /// Builds summary from repositories directly so we never read
  /// [dashboardProvider] while its dependencies are mid-invalidation.
  Future<void> syncHomeWidget() => _afterMutation(checkBudget: false);

  Future<void> _afterMutation({bool checkBudget = true}) async {
    final analytics = _ref.read(analyticsServiceProvider);
    final settings = _ref.read(settingsRepositoryProvider).get();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final budget = _ref
            .read(budgetRepositoryProvider)
            .getOverallForMonth(month)
            ?.amount ??
        settings.monthlyBudget;

    final dash = analytics.buildDashboard(
      transactions: _repo.getAll(),
      budgetAmount: budget,
      month: month,
    );

    final txs = _repo.getAll();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayExpense = txs
        .where(
          (t) =>
              t.isExpense &&
              !t.date.isBefore(todayStart) &&
              t.date.isBefore(todayEnd),
        )
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    await _ref.read(homeWidgetServiceProvider).updateSummary(
          balance: dash.balance,
          todayExpense: todayExpense,
          monthExpense: dash.totalExpense,
          budgetProgress: dash.budgetProgress,
          currencyCode: settings.currencyCode,
        );

    if (!checkBudget) return;
    await _maybeAlertBudget(dash.budgetProgress, now);
  }

  Future<void> _maybeAlertBudget(double progress, DateTime now) async {
    final threshold = progress >= 1.0
        ? 1.0
        : progress >= 0.8
            ? 0.8
            : null;
    if (threshold == null) return;

    final last = _lastBudgetAlertAt;
    final sameDay = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    if (sameDay && _lastAlertThreshold != null && threshold <= _lastAlertThreshold!) {
      return;
    }

    _lastBudgetAlertAt = now;
    _lastAlertThreshold = threshold;

    if (threshold >= 1.0) {
      await _ref.read(notificationServiceProvider).showOverspendWarning(
            'You\'ve exceeded your monthly budget.',
          );
    } else {
      await _ref.read(notificationServiceProvider).showOverspendWarning(
            'You\'ve used ${(progress * 100).toStringAsFixed(0)}% of your budget.',
          );
    }
  }
}

final transactionControllerProvider = Provider((ref) {
  return TransactionController(ref);
});

class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  Future<void> update(AppSettingsModel settings) async {
    await _ref.read(settingsRepositoryProvider).save(settings);
    await _ref.read(notificationServiceProvider).scheduleBudgetReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
          enabled: settings.budgetRemindersEnabled,
        );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final current = _ref.read(settingsRepositoryProvider).get();
    await update(current.copyWith(themeMode: mode));
  }

  Future<void> setVisualStyle(AppVisualStyle style) async {
    final current = _ref.read(settingsRepositoryProvider).get();
    await update(current.copyWith(visualStyle: style));
  }

  Future<void> setCurrency(String code) async {
    final current = _ref.read(settingsRepositoryProvider).get();
    await update(current.copyWith(currencyCode: code));
  }

  Future<void> setMonthlyBudget(double amount) async {
    final current = _ref.read(settingsRepositoryProvider).get();
    await update(current.copyWith(monthlyBudget: amount));
    final now = DateTime.now();
    await _ref.read(budgetRepositoryProvider).upsert(
          BudgetModel(
            id: '',
            amount: amount,
            month: DateTime(now.year, now.month),
            createdAt: now,
          ),
        );
  }

  Future<void> resetAllData() async {
    await HiveDatabase.clearAll();
    await _ref.read(seedServiceProvider).ensureDefaults(loadSampleData: false);
  }
}

final settingsControllerProvider = Provider((ref) => SettingsController(ref));
