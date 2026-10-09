import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

typedef ExternalRouteHandler = void Function(String route);

/// Long-press launcher shortcuts for quick add flows.
class AppShortcutsService {
  AppShortcutsService();

  static const addExpenseType = 'add_expense';
  static const addIncomeType = 'add_income';

  final QuickActions _quickActions = const QuickActions();
  ExternalRouteHandler? onRouteRequested;
  bool _initialized = false;

  Future<void> init({required ExternalRouteHandler onRouteRequested}) async {
    this.onRouteRequested = onRouteRequested;
    if (_initialized) return;
    _initialized = true;

    try {
      await _quickActions.initialize((shortcutType) {
        final route = routeFromShortcutType(shortcutType);
        if (route != null) {
          this.onRouteRequested?.call(route);
        }
      }).timeout(const Duration(seconds: 2));

      await _quickActions.setShortcutItems(const [
        ShortcutItem(
          type: addExpenseType,
          localizedTitle: 'Add Expense',
        ),
        ShortcutItem(
          type: addIncomeType,
          localizedTitle: 'Add Income',
        ),
      ]).timeout(const Duration(seconds: 2));
    } catch (e, st) {
      debugPrint('AppShortcutsService.init failed: $e\n$st');
    }
  }

  static String? routeFromShortcutType(String type) {
    return switch (type) {
      addExpenseType => '/add?type=expense',
      addIncomeType => '/add?type=income',
      _ => null,
    };
  }
}
