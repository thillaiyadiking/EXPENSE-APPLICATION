import 'package:uuid/uuid.dart';

import '../data/default_data.dart';
import '../data/hive_database.dart';
import '../models/models.dart';

abstract class TransactionRepository {
  List<TransactionModel> getAll();
  TransactionModel? getById(String id);
  Future<void> add(TransactionModel transaction);
  Future<void> update(TransactionModel transaction);
  Future<void> delete(String id);
  Stream<List<TransactionModel>> watchAll();
}

class HiveTransactionRepository implements TransactionRepository {
  final _uuid = const Uuid();

  @override
  List<TransactionModel> getAll() {
    final list = HiveDatabase.transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  TransactionModel? getById(String id) => HiveDatabase.transactions.get(id);

  @override
  Future<void> add(TransactionModel transaction) async {
    final tx = transaction.id.isEmpty
        ? transaction.copyWith(id: _uuid.v4())
        : transaction;
    await HiveDatabase.transactions.put(tx.id, tx);
    await _adjustAccountBalance(tx.accountId, tx.signedAmount);
  }

  @override
  Future<void> update(TransactionModel transaction) async {
    final existing = HiveDatabase.transactions.get(transaction.id);
    if (existing != null) {
      await _adjustAccountBalance(existing.accountId, -existing.signedAmount);
    }
    final updated = transaction.copyWith(updatedAt: DateTime.now());
    await HiveDatabase.transactions.put(updated.id, updated);
    await _adjustAccountBalance(updated.accountId, updated.signedAmount);
  }

  @override
  Future<void> delete(String id) async {
    final existing = HiveDatabase.transactions.get(id);
    if (existing != null) {
      await _adjustAccountBalance(existing.accountId, -existing.signedAmount);
      await HiveDatabase.transactions.delete(id);
    }
  }

  @override
  Stream<List<TransactionModel>> watchAll() async* {
    yield getAll();
    yield* HiveDatabase.transactions.watch().map((_) => getAll());
  }

  Future<void> _adjustAccountBalance(String accountId, double delta) async {
    final account = HiveDatabase.accounts.get(accountId);
    if (account == null) return;
    account.balance += delta;
    await account.save();
  }
}

abstract class CategoryRepository {
  List<CategoryModel> getAll();
  CategoryModel? getById(String id);
  Future<void> add(CategoryModel category);
  Future<void> update(CategoryModel category);
  Future<void> delete(String id);
  Stream<List<CategoryModel>> watchAll();
}

class HiveCategoryRepository implements CategoryRepository {
  final _uuid = const Uuid();

  @override
  List<CategoryModel> getAll() {
    final list = HiveDatabase.categories.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  CategoryModel? getById(String id) => HiveDatabase.categories.get(id);

  @override
  Future<void> add(CategoryModel category) async {
    final cat = category.id.isEmpty
        ? category.copyWith(id: _uuid.v4())
        : category;
    await HiveDatabase.categories.put(cat.id, cat);
  }

  @override
  Future<void> update(CategoryModel category) async {
    await HiveDatabase.categories.put(category.id, category);
  }

  @override
  Future<void> delete(String id) async {
    final cat = HiveDatabase.categories.get(id);
    if (cat != null && !cat.isDefault) {
      await HiveDatabase.categories.delete(id);
    }
  }

  @override
  Stream<List<CategoryModel>> watchAll() async* {
    yield getAll();
    yield* HiveDatabase.categories.watch().map((_) => getAll());
  }
}

abstract class BudgetRepository {
  List<BudgetModel> getAll();
  BudgetModel? getOverallForMonth(DateTime month);
  List<BudgetModel> getCategoryBudgetsForMonth(DateTime month);
  Future<void> upsert(BudgetModel budget);
  Future<void> delete(String id);
  List<BudgetHistoryModel> getHistory();
  Future<void> saveHistory(BudgetHistoryModel entry);
  Stream<List<BudgetModel>> watchAll();
}

class HiveBudgetRepository implements BudgetRepository {
  final _uuid = const Uuid();

  DateTime _normalizeMonth(DateTime m) => DateTime(m.year, m.month);

  @override
  List<BudgetModel> getAll() => HiveDatabase.budgets.values.toList();

  @override
  BudgetModel? getOverallForMonth(DateTime month) {
    final m = _normalizeMonth(month);
    try {
      return HiveDatabase.budgets.values.firstWhere(
        (b) =>
            b.categoryId == null &&
            b.month.year == m.year &&
            b.month.month == m.month,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<BudgetModel> getCategoryBudgetsForMonth(DateTime month) {
    final m = _normalizeMonth(month);
    return HiveDatabase.budgets.values
        .where(
          (b) =>
              b.categoryId != null &&
              b.month.year == m.year &&
              b.month.month == m.month,
        )
        .toList();
  }

  @override
  Future<void> upsert(BudgetModel budget) async {
    final normalized = budget.copyWith(
      id: budget.id.isEmpty ? _uuid.v4() : budget.id,
      month: _normalizeMonth(budget.month),
      createdAt: budget.createdAt ?? DateTime.now(),
    );

    // Replace existing for same month+category
    final existing = HiveDatabase.budgets.values.where(
      (b) =>
          b.categoryId == normalized.categoryId &&
          b.month.year == normalized.month.year &&
          b.month.month == normalized.month.month,
    );
    for (final e in existing) {
      await HiveDatabase.budgets.delete(e.id);
    }
    await HiveDatabase.budgets.put(normalized.id, normalized);
  }

  @override
  Future<void> delete(String id) => HiveDatabase.budgets.delete(id);

  @override
  List<BudgetHistoryModel> getHistory() {
    final list = HiveDatabase.budgetHistory.values.toList();
    list.sort((a, b) => b.month.compareTo(a.month));
    return list;
  }

  @override
  Future<void> saveHistory(BudgetHistoryModel entry) async {
    final e = entry.id.isEmpty
        ? BudgetHistoryModel(
            id: _uuid.v4(),
            month: entry.month,
            budgetAmount: entry.budgetAmount,
            spentAmount: entry.spentAmount,
            categoryId: entry.categoryId,
          )
        : entry;
    await HiveDatabase.budgetHistory.put(e.id, e);
  }

  @override
  Stream<List<BudgetModel>> watchAll() async* {
    yield getAll();
    yield* HiveDatabase.budgets.watch().map((_) => getAll());
  }
}

abstract class AccountRepository {
  List<AccountModel> getAll();
  AccountModel? getById(String id);
  AccountModel? getDefault();
  Future<void> add(AccountModel account);
  Future<void> update(AccountModel account);
  Future<void> delete(String id);
  Stream<List<AccountModel>> watchAll();
}

class HiveAccountRepository implements AccountRepository {
  final _uuid = const Uuid();

  @override
  List<AccountModel> getAll() {
    final list = HiveDatabase.accounts.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  AccountModel? getById(String id) => HiveDatabase.accounts.get(id);

  @override
  AccountModel? getDefault() {
    try {
      return getAll().firstWhere((a) => a.isDefault);
    } catch (_) {
      final all = getAll();
      return all.isEmpty ? null : all.first;
    }
  }

  @override
  Future<void> add(AccountModel account) async {
    final acc = account.id.isEmpty
        ? account.copyWith(id: _uuid.v4())
        : account;
    await HiveDatabase.accounts.put(acc.id, acc);
  }

  @override
  Future<void> update(AccountModel account) async {
    await HiveDatabase.accounts.put(account.id, account);
  }

  @override
  Future<void> delete(String id) async {
    final acc = HiveDatabase.accounts.get(id);
    if (acc != null && !acc.isDefault) {
      await HiveDatabase.accounts.delete(id);
    }
  }

  @override
  Stream<List<AccountModel>> watchAll() async* {
    yield getAll();
    yield* HiveDatabase.accounts.watch().map((_) => getAll());
  }
}

abstract class SettingsRepository {
  AppSettingsModel get();
  Future<void> save(AppSettingsModel settings);
  Stream<AppSettingsModel> watch();
}

class HiveSettingsRepository implements SettingsRepository {
  static const _key = 'settings';

  @override
  AppSettingsModel get() {
    return HiveDatabase.settings.get(_key) ?? AppSettingsModel();
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    await HiveDatabase.settings.put(_key, settings);
  }

  @override
  Stream<AppSettingsModel> watch() async* {
    yield get();
    yield* HiveDatabase.settings.watch().map((_) => get());
  }
}

abstract class TagRepository {
  List<TagModel> getAll();
  Future<void> add(TagModel tag);
  Future<void> delete(String id);
}

class HiveTagRepository implements TagRepository {
  final _uuid = const Uuid();

  @override
  List<TagModel> getAll() => HiveDatabase.tags.values.toList();

  @override
  Future<void> add(TagModel tag) async {
    final t = tag.id.isEmpty
        ? TagModel(id: _uuid.v4(), name: tag.name, colorValue: tag.colorValue)
        : tag;
    await HiveDatabase.tags.put(t.id, t);
  }

  @override
  Future<void> delete(String id) => HiveDatabase.tags.delete(id);
}

class SeedService {
  SeedService({
    required this.categoryRepo,
    required this.accountRepo,
    required this.tagRepo,
    required this.transactionRepo,
    required this.budgetRepo,
    required this.settingsRepo,
  });

  final CategoryRepository categoryRepo;
  final AccountRepository accountRepo;
  final TagRepository tagRepo;
  final TransactionRepository transactionRepo;
  final BudgetRepository budgetRepo;
  final SettingsRepository settingsRepo;

  Future<void> ensureDefaults({bool loadSampleData = false}) async {
    if (categoryRepo.getAll().isEmpty) {
      for (final c in DefaultData.defaultCategories()) {
        await categoryRepo.add(c);
      }
    }
    if (accountRepo.getAll().isEmpty) {
      for (final a in DefaultData.defaultAccounts()) {
        await accountRepo.add(a);
      }
    }
    if (tagRepo.getAll().isEmpty) {
      for (final t in DefaultData.defaultTags()) {
        await tagRepo.add(t);
      }
    }

    var settings = settingsRepo.get();
    final now = DateTime.now();

    // Remove previously seeded demo/fake transactions once.
    if (settings.sampleDataLoaded) {
      await HiveDatabase.transactions.clear();
      for (final acc in accountRepo.getAll()) {
        await accountRepo.update(acc.copyWith(balance: 0));
      }
      settings = settings.copyWith(sampleDataLoaded: false);
      await settingsRepo.save(settings);
    }

    if (budgetRepo.getOverallForMonth(now) == null) {
      await budgetRepo.upsert(
        BudgetModel(
          id: 'budget_overall',
          amount: settings.monthlyBudget,
          month: DateTime(now.year, now.month),
          createdAt: now,
        ),
      );
    }

    // Sample/demo data is intentionally never auto-loaded.
    if (loadSampleData && transactionRepo.getAll().isEmpty) {
      for (final tx in DefaultData.sampleTransactions()) {
        await transactionRepo.add(tx);
      }
    }
  }
}
