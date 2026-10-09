import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketflow/core/utils/formatters.dart';
import 'package:pocketflow/domain/entities/analytics_entities.dart';
import 'package:pocketflow/models/models.dart';
import 'package:pocketflow/services/analytics_service.dart';

void main() {
  group('MoneyFormatter', () {
    test('formats positive amounts with currency symbol', () {
      final result = MoneyFormatter.format(1234.5, currencyCode: 'USD');
      expect(result, contains('1,234.50'));
      expect(result, contains('\$'));
    });

    test('formats negative amounts with minus sign', () {
      final result = MoneyFormatter.format(-42, currencyCode: 'USD');
      expect(result, contains('−'));
      expect(result, contains('42.00'));
    });

    test('showSign adds plus for positive', () {
      final result = MoneyFormatter.format(
        10,
        currencyCode: 'USD',
        showSign: true,
      );
      expect(result.startsWith('+'), isTrue);
    });
  });

  group('PeriodHelper', () {
    test('startOfMonth returns first day', () {
      final d = PeriodHelper.startOfMonth(DateTime(2026, 7, 29));
      expect(d.day, 1);
      expect(d.month, 7);
      expect(d.year, 2026);
    });

    test('lastNMonths returns correct length', () {
      expect(PeriodHelper.lastNMonths(6), hasLength(6));
    });
  });

  group('TransactionModel', () {
    test('signedAmount for expense is negative', () {
      final tx = TransactionModel(
        id: '1',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'c',
        accountId: 'a',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, -50);
    });

    test('signedAmount for income is positive', () {
      final tx = TransactionModel(
        id: '1',
        amount: 100,
        type: TransactionType.income,
        categoryId: 'c',
        accountId: 'a',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, 100);
    });

    test('signedAmount for refund is positive', () {
      final tx = TransactionModel(
        id: '1',
        amount: 25,
        type: TransactionType.refund,
        categoryId: 'c',
        accountId: 'a',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, 25);
    });

    test('json roundtrip', () {
      final tx = TransactionModel(
        id: 'abc',
        amount: 12.34,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_cash',
        date: DateTime(2026, 1, 15),
        note: 'Lunch',
        tags: const ['tag_work'],
        createdAt: DateTime(2026, 1, 15),
      );
      final restored = TransactionModel.fromJson(tx.toJson());
      expect(restored.id, tx.id);
      expect(restored.amount, tx.amount);
      expect(restored.type, tx.type);
      expect(restored.note, tx.note);
      expect(restored.tags, tx.tags);
    });
  });

  group('AnalyticsService', () {
    final service = AnalyticsService();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    final txs = [
      TransactionModel(
        id: '1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'cash',
        date: month.add(const Duration(days: 2)),
        createdAt: now,
      ),
      TransactionModel(
        id: '2',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'transport',
        accountId: 'cash',
        date: month.add(const Duration(days: 3)),
        note: 'Uber',
        createdAt: now,
      ),
      TransactionModel(
        id: '3',
        amount: 1000,
        type: TransactionType.income,
        categoryId: 'salary',
        accountId: 'bank',
        date: month.add(const Duration(days: 1)),
        createdAt: now,
      ),
    ];

    test('buildDashboard computes income expense and balance', () {
      final dash = service.buildDashboard(
        transactions: txs,
        budgetAmount: 500,
        month: month,
      );
      expect(dash.totalIncome, 1000);
      expect(dash.totalExpense, 150);
      expect(dash.balance, 850);
      expect(dash.budgetRemaining, 350);
      expect(dash.categoryBreakdown['food'], 100);
    });

    test('filter by query matches note', () {
      final filtered = service.filterTransactions(
        txs,
        const TransactionFilter(query: 'uber'),
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.id, '2');
    });

    test('filter by category', () {
      final filtered = service.filterTransactions(
        txs,
        TransactionFilter(categoryIds: {'food'}),
      );
      expect(filtered, hasLength(1));
    });

    test('filter by type', () {
      final filtered = service.filterTransactions(
        txs,
        TransactionFilter(types: {TransactionType.income}),
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.isIncome, isTrue);
    });

    test('sort by amount ascending', () {
      final filtered = service.filterTransactions(
        txs,
        const TransactionFilter(
          sortField: SortField.amount,
          sortOrder: SortOrder.ascending,
        ),
      );
      expect(filtered.first.amount, 50);
      expect(filtered.last.amount, 1000);
    });

    test('topCategories returns sorted percentages', () {
      final tops = service.topCategories({'food': 100, 'transport': 50});
      expect(tops.first.categoryId, 'food');
      expect(tops.first.percentage, closeTo(100 / 150, 0.001));
    });

    test('categoryPie only includes expenses', () {
      final pie = service.categoryPie(txs, month: month);
      expect(pie.containsKey('salary'), isFalse);
      expect(pie['food'], 100);
    });

    test('monthlyTrends returns requested months', () {
      final trends = service.monthlyTrends(txs, months: 3);
      expect(trends, hasLength(3));
    });
  });

  group('BudgetModel', () {
    test('isOverall when categoryId is null', () {
      final b = BudgetModel(
        id: '1',
        amount: 2000,
        month: DateTime(2026, 7),
      );
      expect(b.isOverall, isTrue);
    });
  });

  group('AppSettingsModel', () {
    test('theme mapping', () {
      expect(
        AppSettingsModel(themeMode: AppThemeMode.dark).flutterThemeMode,
        equals(ThemeMode.dark),
      );
    });
  });
}
