import 'package:intl/intl.dart';

import '../constants/currencies.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static String format(
    double amount, {
    required String currencyCode,
    bool showSign = false,
    bool compact = false,
  }) {
    final currency = findCurrency(currencyCode);
    final symbol = currency?.symbol ?? currencyCode;
    final abs = amount.abs();

    final String number;
    if (compact && abs >= 1000) {
      number = NumberFormat.compact(locale: 'en').format(abs);
    } else {
      number = NumberFormat('#,##0.00', 'en').format(abs);
    }

    final prefix = showSign
        ? (amount > 0
            ? '+'
            : amount < 0
                ? '−'
                : '')
        : (amount < 0 ? '−' : '');

    return '$prefix$symbol$number';
  }
}

class DateFormatters {
  DateFormatters._();

  static String medium(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String short(DateTime date) => DateFormat('MMM d').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String weekday(DateTime date) => DateFormat('EEEE').format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return weekday(date);
    return medium(date);
  }
}

class PeriodHelper {
  PeriodHelper._();

  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month);
  }

  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
  }

  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? DateTime.now();
    final weekday = d.weekday;
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  static DateTime endOfWeek([DateTime? date]) {
    final start = startOfWeek(date);
    return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  static List<DateTime> lastNMonths(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final m = DateTime(now.year, now.month - (n - 1 - i));
      return DateTime(m.year, m.month);
    });
  }
}
