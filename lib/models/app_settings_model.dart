import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';

enum AppThemeMode { system, light, dark }

enum AppVisualStyle { classic, rich }

class AppSettingsModel extends HiveObject {
  AppSettingsModel({
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.themeMode = AppThemeMode.system,
    this.monthlyBudget = AppConstants.defaultMonthlyBudget,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.pinHash,
    this.budgetRemindersEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.onboardingComplete = false,
    this.sampleDataLoaded = false,
    this.visualStyle = AppVisualStyle.classic,
  });

  String currencyCode;
  AppThemeMode themeMode;
  double monthlyBudget;
  bool pinEnabled;
  bool biometricEnabled;
  String? pinHash;
  bool budgetRemindersEnabled;
  int reminderHour;
  int reminderMinute;
  bool onboardingComplete;
  bool sampleDataLoaded;
  AppVisualStyle visualStyle;

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  AppSettingsModel copyWith({
    String? currencyCode,
    AppThemeMode? themeMode,
    double? monthlyBudget,
    bool? pinEnabled,
    bool? biometricEnabled,
    String? pinHash,
    bool? budgetRemindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? onboardingComplete,
    bool? sampleDataLoaded,
    AppVisualStyle? visualStyle,
    bool clearPin = false,
  }) {
    return AppSettingsModel(
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      budgetRemindersEnabled:
          budgetRemindersEnabled ?? this.budgetRemindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      sampleDataLoaded: sampleDataLoaded ?? this.sampleDataLoaded,
      visualStyle: visualStyle ?? this.visualStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'themeMode': themeMode.name,
        'monthlyBudget': monthlyBudget,
        'pinEnabled': pinEnabled,
        'biometricEnabled': biometricEnabled,
        'pinHash': pinHash,
        'budgetRemindersEnabled': budgetRemindersEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'onboardingComplete': onboardingComplete,
        'sampleDataLoaded': sampleDataLoaded,
        'visualStyle': visualStyle.name,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      currencyCode: json['currencyCode'] as String? ??
          AppConstants.defaultCurrencyCode,
      themeMode: AppThemeMode.values.byName(
        json['themeMode'] as String? ?? 'system',
      ),
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ??
          AppConstants.defaultMonthlyBudget,
      pinEnabled: json['pinEnabled'] as bool? ?? false,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      pinHash: json['pinHash'] as String?,
      budgetRemindersEnabled: json['budgetRemindersEnabled'] as bool? ?? true,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      sampleDataLoaded: json['sampleDataLoaded'] as bool? ?? false,
      visualStyle: AppVisualStyle.values.byName(
        json['visualStyle'] as String? ?? 'classic',
      ),
    );
  }
}

class TagModel extends HiveObject {
  TagModel({required this.id, required this.name, this.colorValue = 0xFF64748B});

  final String id;
  String name;
  int colorValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int? ?? 0xFF64748B,
    );
  }
}

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 4;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final styleIndex = fields[11] as int? ?? 0;
    return AppSettingsModel(
      currencyCode: fields[0] as String? ?? AppConstants.defaultCurrencyCode,
      themeMode: AppThemeMode.values[fields[1] as int? ?? 0],
      monthlyBudget: fields[2] as double? ?? AppConstants.defaultMonthlyBudget,
      pinEnabled: fields[3] as bool? ?? false,
      biometricEnabled: fields[4] as bool? ?? false,
      pinHash: fields[5] as String?,
      budgetRemindersEnabled: fields[6] as bool? ?? true,
      reminderHour: fields[7] as int? ?? 20,
      reminderMinute: fields[8] as int? ?? 0,
      onboardingComplete: fields[9] as bool? ?? false,
      sampleDataLoaded: fields[10] as bool? ?? false,
      visualStyle: styleIndex < AppVisualStyle.values.length
          ? AppVisualStyle.values[styleIndex]
          : AppVisualStyle.classic,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.currencyCode)
      ..writeByte(1)
      ..write(obj.themeMode.index)
      ..writeByte(2)
      ..write(obj.monthlyBudget)
      ..writeByte(3)
      ..write(obj.pinEnabled)
      ..writeByte(4)
      ..write(obj.biometricEnabled)
      ..writeByte(5)
      ..write(obj.pinHash)
      ..writeByte(6)
      ..write(obj.budgetRemindersEnabled)
      ..writeByte(7)
      ..write(obj.reminderHour)
      ..writeByte(8)
      ..write(obj.reminderMinute)
      ..writeByte(9)
      ..write(obj.onboardingComplete)
      ..writeByte(10)
      ..write(obj.sampleDataLoaded)
      ..writeByte(11)
      ..write(obj.visualStyle.index);
  }
}

class TagModelAdapter extends TypeAdapter<TagModel> {
  @override
  final int typeId = 5;

  @override
  TagModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int? ?? 0xFF64748B,
    );
  }

  @override
  void write(BinaryWriter writer, TagModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue);
  }
}
