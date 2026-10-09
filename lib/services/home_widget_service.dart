import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../core/utils/formatters.dart';

typedef ExternalRouteHandler = void Function(String route);

enum PinWidgetResult { unsupported, alreadyPinned, prompted }

/// Syncs glance data to the Android home-screen Money Glance widget.
class HomeWidgetService {
  HomeWidgetService();

  static const androidWidgetName = 'PocketFlowWidgetProvider';
  static const addExpenseUri = 'pocketflow://add?type=expense';
  static const homeUri = 'pocketflow://home';

  ExternalRouteHandler? onRouteRequested;
  StreamSubscription<Uri?>? _clickSub;
  bool _initialized = false;

  Future<void> init({required ExternalRouteHandler onRouteRequested}) async {
    this.onRouteRequested = onRouteRequested;
    if (_initialized) return;
    _initialized = true;

    try {
      final launched = await HomeWidget.initiallyLaunchedFromHomeWidget()
          .timeout(const Duration(seconds: 2));
      _handleUri(launched);

      _clickSub = HomeWidget.widgetClicked.listen(_handleUri);
    } catch (e, st) {
      debugPrint('HomeWidgetService.init failed: $e\n$st');
    }
  }

  Future<void> updateSummary({
    required double balance,
    required double todayExpense,
    required double monthExpense,
    required double budgetProgress,
    required String currencyCode,
  }) async {
    try {
      final balanceText = MoneyFormatter.format(
        balance,
        currencyCode: currencyCode,
        compact: true,
      );
      final todayText = MoneyFormatter.format(
        todayExpense,
        currencyCode: currencyCode,
        compact: true,
      );
      final monthText = MoneyFormatter.format(
        monthExpense,
        currencyCode: currencyCode,
        compact: true,
      );

      final progressPct =
          (budgetProgress.isFinite ? budgetProgress : 0.0).clamp(0.0, 1.5);
      final progressInt = math.min(100, (progressPct * 100).round());

      final budgetLabel = progressPct >= 1.0
          ? 'Over budget'
          : progressPct >= 0.8
              ? 'Near limit'
              : 'Budget';

      final hint = progressPct >= 1.0
          ? 'Over budget — tap + to log'
          : progressPct >= 0.8
              ? 'Near limit — tap + to add'
              : 'Tap + to add expense';

      final updatedAt = DateFormat('HH:mm').format(DateTime.now());

      await HomeWidget.saveWidgetData<String>('title', 'PocketFlow');
      await HomeWidget.saveWidgetData<String>('balance', balanceText);
      await HomeWidget.saveWidgetData<String>('today_expense', todayText);
      await HomeWidget.saveWidgetData<String>('month_expense', monthText);
      // Legacy key kept for older layouts during upgrade.
      await HomeWidget.saveWidgetData<String>('expense', monthText);
      await HomeWidget.saveWidgetData<String>(
        'expense_label',
        'Spent this month',
      );
      await HomeWidget.saveWidgetData<int>('budget_progress', progressInt);
      await HomeWidget.saveWidgetData<String>('budget_label', budgetLabel);
      await HomeWidget.saveWidgetData<String>('updated_at', 'Updated $updatedAt');
      await HomeWidget.saveWidgetData<String>('hint', hint);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: 'com.example.expense_app.$androidWidgetName',
      );
    } catch (e, st) {
      debugPrint('HomeWidgetService.updateSummary failed: $e\n$st');
    }
  }

  /// True when at least one Money Glance instance is on the home screen.
  Future<bool> isInstalled() async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      return widgets.any((w) {
        final name = w.androidClassName ?? '';
        return name.contains(androidWidgetName);
      });
    } catch (e, st) {
      debugPrint('HomeWidgetService.isInstalled failed: $e\n$st');
      return false;
    }
  }

  /// Asks the launcher to pin the Money Glance widget (Android 8+ where supported).
  /// Returns [PinWidgetResult.alreadyPinned] if a widget is already on the home screen.
  Future<PinWidgetResult> requestPinWidget() async {
    try {
      if (await isInstalled()) {
        return PinWidgetResult.alreadyPinned;
      }
      final supported =
          await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) return PinWidgetResult.unsupported;
      await HomeWidget.requestPinWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: 'com.example.expense_app.$androidWidgetName',
      );
      return PinWidgetResult.prompted;
    } catch (e, st) {
      debugPrint('HomeWidgetService.requestPinWidget failed: $e\n$st');
      return PinWidgetResult.unsupported;
    }
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final route = routeFromUri(uri);
    if (route == null) return;
    onRouteRequested?.call(route);
  }

  /// Maps widget launch URIs to in-app GoRouter locations.
  static String? routeFromUri(Uri uri) {
    // pocketflow://add?type=expense  → host=add
    // pocketflow://add/?type=expense → host=add, path=/
    // pocketflow:///add?type=expense → path=/add
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final hostOrPath = uri.host.isNotEmpty
        ? uri.host
        : (segments.isNotEmpty ? segments.first : '');

    final normalized = hostOrPath.toLowerCase();
    if (normalized == 'home' ||
        uri.path.toLowerCase().contains('home') ||
        segments.any((s) => s.toLowerCase() == 'home')) {
      return '/home';
    }
    if (normalized == 'add' ||
        uri.path.toLowerCase().contains('add') ||
        segments.any((s) => s.toLowerCase() == 'add')) {
      final type = uri.queryParameters['type'] ?? 'expense';
      return '/add?type=$type';
    }
    return null;
  }

  Future<void> dispose() async {
    await _clickSub?.cancel();
    _clickSub = null;
  }
}
