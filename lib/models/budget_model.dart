import 'package:hive/hive.dart';

class BudgetModel extends HiveObject {
  BudgetModel({
    required this.id,
    required this.amount,
    required this.month,
    this.categoryId,
    this.alertThreshold = 0.8,
    this.createdAt,
  });

  final String id;

  /// null categoryId = overall monthly budget
  String? categoryId;
  double amount;
  DateTime month;
  double alertThreshold;
  DateTime? createdAt;

  bool get isOverall => categoryId == null;

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    DateTime? month,
    double? alertThreshold,
    DateTime? createdAt,
    bool clearCategory = false,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      amount: amount ?? this.amount,
      month: month ?? this.month,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'month': month.toIso8601String(),
        'alertThreshold': alertThreshold,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      month: DateTime.parse(json['month'] as String),
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

}

class BudgetHistoryModel extends HiveObject {
  BudgetHistoryModel({
    required this.id,
    required this.month,
    required this.budgetAmount,
    required this.spentAmount,
    this.categoryId,
  });

  final String id;
  DateTime month;
  String? categoryId;
  double budgetAmount;
  double spentAmount;

  double get remaining => budgetAmount - spentAmount;
  bool get wasOverspent => spentAmount > budgetAmount;
  double get progress =>
      budgetAmount <= 0 ? 0 : (spentAmount / budgetAmount).clamp(0, 2);

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month.toIso8601String(),
        'categoryId': categoryId,
        'budgetAmount': budgetAmount,
        'spentAmount': spentAmount,
      };

  factory BudgetHistoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetHistoryModel(
      id: json['id'] as String,
      month: DateTime.parse(json['month'] as String),
      categoryId: json['categoryId'] as String?,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
    );
  }

}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 2;

  @override
  BudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      id: fields[0] as String,
      categoryId: fields[1] as String?,
      amount: fields[2] as double,
      month: fields[3] as DateTime,
      alertThreshold: fields[4] as double? ?? 0.8,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.month)
      ..writeByte(4)
      ..write(obj.alertThreshold)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}

class BudgetHistoryModelAdapter extends TypeAdapter<BudgetHistoryModel> {
  @override
  final int typeId = 6;

  @override
  BudgetHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetHistoryModel(
      id: fields[0] as String,
      month: fields[1] as DateTime,
      categoryId: fields[2] as String?,
      budgetAmount: fields[3] as double,
      spentAmount: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.budgetAmount)
      ..writeByte(4)
      ..write(obj.spentAmount);
  }
}
