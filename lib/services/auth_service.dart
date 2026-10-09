import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AuthService {
  AuthService()
      : _storage = const FlutterSecureStorage(),
        _localAuth = LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'pocketflow_pin_hash';
  static const _unlockedKey = 'pocketflow_session_unlocked';

  String hashPin(String pin) {
    final bytes = utf8.encode('pocketflow_salt::$pin');
    var hash = 0;
    for (final b in bytes) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    return base64Encode(utf8.encode('$hash:${pin.length}:${bytes.length}'));
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == hashPin(pin);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinKey)) != null;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      // MIUI often reports canCheck=false briefly; enrolled types still work.
      return canCheck || available.isNotEmpty || supported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      // Stop any previous prompt (common when auto-prompt + button race).
      await _localAuth.stopAuthentication();
      return await _localAuth.authenticate(
        localizedReason: 'Unlock PocketFlow',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<void> markUnlocked() async {
    await _storage.write(key: _unlockedKey, value: '1');
  }

  Future<void> lock() async {
    await _storage.delete(key: _unlockedKey);
  }

  Future<bool> isSessionUnlocked() async {
    return (await _storage.read(key: _unlockedKey)) == '1';
  }
}

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static void ensureLocalTimeZone() {
    tz.initializeTimeZones();
    try {
      // Already configured.
      final _ = tz.local.name;
      return;
    } catch (_) {
      // Fall through and set a location.
    }

    final offset = DateTime.now().timeZoneOffset;
    final locationName = switch ((offset.inHours, offset.inMinutes % 60)) {
      (5, 30) || (5, -30) => 'Asia/Kolkata',
      (0, 0) => 'UTC',
      (8, 0) => 'Asia/Shanghai',
      (-5, 0) => 'America/New_York',
      _ => 'Asia/Kolkata',
    };

    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> init() async {
    if (_ready) return;

    ensureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Never block startup on MIUI/Android permission dialogs — they can hang forever.
    unawaited(_requestPermissionSafely());

    _ready = true;
  }

  Future<void> _requestPermissionSafely() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      await android
          .requestNotificationsPermission()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Permission can be granted later from system settings.
    }
  }

  Future<void> scheduleBudgetReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    try {
      await init().timeout(const Duration(seconds: 4));
      await _plugin.cancel(1001);

      if (!enabled) return;

      ensureLocalTimeZone();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        1001,
        'Budget check-in',
        'Review today\'s spending and stay on track with PocketFlow.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_reminders',
            'Budget Reminders',
            channelDescription: 'Daily budget reminder notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Reminder scheduling must never block or crash app start.
    }
  }

  Future<void> showOverspendWarning(String message) async {
    try {
      await init().timeout(const Duration(seconds: 4));
      await _plugin.show(
        1002,
        'Budget alert',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            'Budget Alerts',
            channelDescription: 'Overspending and budget threshold alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Ignore notification failures.
    }
  }
}
