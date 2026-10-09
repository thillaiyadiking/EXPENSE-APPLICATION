import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';

class DefaultData {
  DefaultData._();

  static List<CategoryModel> defaultCategories() {
    final defs = <(String, String, IconData, Color)>[
      ('cat_food', 'Food', Icons.restaurant_rounded, AppColors.categoryPalette[0]),
      ('cat_transport', 'Transport', Icons.directions_car_rounded, AppColors.categoryPalette[1]),
      ('cat_shopping', 'Shopping', Icons.shopping_bag_rounded, AppColors.categoryPalette[2]),
      ('cat_entertainment', 'Entertainment', Icons.movie_rounded, AppColors.categoryPalette[3]),
      ('cat_bills', 'Bills', Icons.receipt_long_rounded, AppColors.categoryPalette[4]),
      ('cat_health', 'Health', Icons.favorite_rounded, AppColors.categoryPalette[5]),
      ('cat_education', 'Education', Icons.school_rounded, AppColors.categoryPalette[6]),
      ('cat_travel', 'Travel', Icons.flight_rounded, AppColors.categoryPalette[7]),
      ('cat_other', 'Other', Icons.more_horiz_rounded, AppColors.categoryPalette[8]),
      ('cat_salary', 'Salary', Icons.payments_rounded, AppColors.income),
      ('cat_freelance', 'Freelance', Icons.work_rounded, const Color(0xFF0EA5E9)),
    ];

    return [
      for (var i = 0; i < defs.length; i++)
        CategoryModel(
          id: defs[i].$1,
          name: defs[i].$2,
          iconCode: defs[i].$3.codePoint,
          colorValue: defs[i].$4.toARGB32(),
          isDefault: true,
          isIncome: defs[i].$1 == 'cat_salary' || defs[i].$1 == 'cat_freelance',
          sortOrder: i,
        ),
    ];
  }

  static List<AccountModel> defaultAccounts() {
    return [
      AccountModel(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        colorValue: const Color(0xFF10B981).toARGB32(),
        iconCode: Icons.payments_rounded.codePoint,
        isDefault: true,
        sortOrder: 0,
      ),
      AccountModel(
        id: 'acc_bank',
        name: 'Bank',
        type: AccountType.bank,
        colorValue: const Color(0xFF3B82F6).toARGB32(),
        iconCode: Icons.account_balance_rounded.codePoint,
        sortOrder: 1,
      ),
      AccountModel(
        id: 'acc_wallet',
        name: 'Wallet',
        type: AccountType.wallet,
        colorValue: const Color(0xFF8B5CF6).toARGB32(),
        iconCode: Icons.account_balance_wallet_rounded.codePoint,
        sortOrder: 2,
      ),
      AccountModel(
        id: 'acc_card',
        name: 'Card',
        type: AccountType.card,
        colorValue: const Color(0xFFF59E0B).toARGB32(),
        iconCode: Icons.credit_card_rounded.codePoint,
        sortOrder: 3,
      ),
    ];
  }

  static List<TagModel> defaultTags() {
    return [
      TagModel(id: 'tag_work', name: 'Work', colorValue: 0xFF3B82F6),
      TagModel(id: 'tag_personal', name: 'Personal', colorValue: 0xFFEC4899),
      TagModel(id: 'tag_family', name: 'Family', colorValue: 0xFF10B981),
      TagModel(id: 'tag_urgent', name: 'Urgent', colorValue: 0xFFEF4444),
    ];
  }

  static List<TransactionModel> sampleTransactions() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    return [
      TransactionModel(
        id: 'tx_salary',
        amount: 4500,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        accountId: 'acc_bank',
        date: month.add(const Duration(days: 1)),
        note: 'Monthly salary',
        tags: const ['tag_work'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_rent',
        amount: 1200,
        type: TransactionType.expense,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        date: month.add(const Duration(days: 2)),
        note: 'Apartment rent',
        tags: const ['tag_personal'],
        recurrence: RecurrenceRule.monthly,
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_groceries',
        amount: 86.40,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 1)),
        note: 'Weekly groceries',
        tags: const ['tag_family'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_uber',
        amount: 18.50,
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        accountId: 'acc_wallet',
        date: now.subtract(const Duration(hours: 5)),
        note: 'Airport ride',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_coffee',
        amount: 5.75,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_cash',
        date: now.subtract(const Duration(hours: 2)),
        note: 'Morning coffee',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_netflix',
        amount: 15.99,
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        accountId: 'acc_card',
        date: month.add(const Duration(days: 5)),
        note: 'Streaming subscription',
        recurrence: RecurrenceRule.monthly,
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_clothes',
        amount: 129.00,
        type: TransactionType.expense,
        categoryId: 'cat_shopping',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 3)),
        note: 'Weekend shopping',
        tags: const ['tag_personal'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_gym',
        amount: 45.00,
        type: TransactionType.expense,
        categoryId: 'cat_health',
        accountId: 'acc_bank',
        date: month.add(const Duration(days: 3)),
        note: 'Gym membership',
        recurrence: RecurrenceRule.monthly,
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_course',
        amount: 79.00,
        type: TransactionType.expense,
        categoryId: 'cat_education',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 6)),
        note: 'Online course',
        tags: const ['tag_work'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_freelance',
        amount: 650,
        type: TransactionType.income,
        categoryId: 'cat_freelance',
        accountId: 'acc_bank',
        date: now.subtract(const Duration(days: 4)),
        note: 'Design project',
        tags: const ['tag_work'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_refund',
        amount: 32.50,
        type: TransactionType.refund,
        categoryId: 'cat_shopping',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 2)),
        note: 'Returned jacket',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_dinner',
        amount: 54.20,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 2, hours: 3)),
        note: 'Dinner with friends',
        tags: const ['tag_personal'],
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_fuel',
        amount: 48.00,
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        accountId: 'acc_cash',
        date: now.subtract(const Duration(days: 5)),
        note: 'Fuel',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_hotel',
        amount: 210.00,
        type: TransactionType.expense,
        categoryId: 'cat_travel',
        accountId: 'acc_card',
        date: now.subtract(const Duration(days: 10)),
        note: 'Weekend getaway',
        tags: const ['tag_personal'],
        createdAt: now,
      ),
      // Previous month samples for trends
      TransactionModel(
        id: 'tx_prev_salary',
        amount: 4500,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        accountId: 'acc_bank',
        date: DateTime(now.year, now.month - 1, 1),
        note: 'Monthly salary',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_prev_food',
        amount: 320,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_card',
        date: DateTime(now.year, now.month - 1, 15),
        note: 'Food last month',
        createdAt: now,
      ),
      TransactionModel(
        id: 'tx_prev_bills',
        amount: 980,
        type: TransactionType.expense,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        date: DateTime(now.year, now.month - 1, 3),
        note: 'Bills last month',
        createdAt: now,
      ),
    ];
  }
}
