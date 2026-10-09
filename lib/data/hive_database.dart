import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';

class HiveDatabase {
  HiveDatabase._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BudgetModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TagModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(BudgetHistoryModelAdapter());
    }

    await Future.wait([
      Hive.openBox<TransactionModel>(AppConstants.hiveBoxTransactions),
      Hive.openBox<CategoryModel>(AppConstants.hiveBoxCategories),
      Hive.openBox<BudgetModel>(AppConstants.hiveBoxBudgets),
      Hive.openBox<AccountModel>(AppConstants.hiveBoxAccounts),
      Hive.openBox<AppSettingsModel>(AppConstants.hiveBoxSettings),
      Hive.openBox<TagModel>(AppConstants.hiveBoxTags),
      Hive.openBox<BudgetHistoryModel>(AppConstants.hiveBoxBudgetHistory),
    ]);

    _initialized = true;
  }

  static Box<TransactionModel> get transactions =>
      Hive.box<TransactionModel>(AppConstants.hiveBoxTransactions);

  static Box<CategoryModel> get categories =>
      Hive.box<CategoryModel>(AppConstants.hiveBoxCategories);

  static Box<BudgetModel> get budgets =>
      Hive.box<BudgetModel>(AppConstants.hiveBoxBudgets);

  static Box<AccountModel> get accounts =>
      Hive.box<AccountModel>(AppConstants.hiveBoxAccounts);

  static Box<AppSettingsModel> get settings =>
      Hive.box<AppSettingsModel>(AppConstants.hiveBoxSettings);

  static Box<TagModel> get tags =>
      Hive.box<TagModel>(AppConstants.hiveBoxTags);

  static Box<BudgetHistoryModel> get budgetHistory =>
      Hive.box<BudgetHistoryModel>(AppConstants.hiveBoxBudgetHistory);

  static Future<void> clearAll() async {
    await Future.wait([
      transactions.clear(),
      categories.clear(),
      budgets.clear(),
      accounts.clear(),
      settings.clear(),
      tags.clear(),
      budgetHistory.clear(),
    ]);
  }
}
