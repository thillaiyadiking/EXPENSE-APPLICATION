import 'package:hive/hive.dart';

enum TransactionType { expense, income, refund }

enum RecurrenceRule { none, daily, weekly, monthly, yearly }

class TransactionModel extends HiveObject {
  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.createdAt,
    this.note = '',
    this.tags = const [],
    this.recurrence = RecurrenceRule.none,
    this.parentRecurringId,
    this.updatedAt,
  });

  final String id;
  double amount;
  TransactionType type;
  String categoryId;
  String accountId;
  DateTime date;
  String note;
  List<String> tags;
  RecurrenceRule recurrence;
  String? parentRecurringId;
  DateTime createdAt;
  DateTime? updatedAt;

  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount.abs();
      case TransactionType.income:
      case TransactionType.refund:
        return amount.abs();
    }
  }

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isRefund => type == TransactionType.refund;

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    List<String>? tags,
    RecurrenceRule? recurrence,
    String? parentRecurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'note': note,
        'tags': tags,
        'recurrence': recurrence.name,
        'parentRecurringId': parentRecurringId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      recurrence: RecurrenceRule.values.byName(
        json['recurrence'] as String? ?? 'none',
      ),
      parentRecurringId: json['parentRecurringId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: TransactionType.values[fields[2] as int],
      categoryId: fields[3] as String,
      accountId: fields[4] as String,
      date: fields[5] as DateTime,
      note: fields[6] as String? ?? '',
      tags: (fields[7] as List?)?.cast<String>() ?? const [],
      recurrence: RecurrenceRule.values[fields[8] as int? ?? 0],
      parentRecurringId: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.recurrence.index)
      ..writeByte(9)
      ..write(obj.parentRecurringId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }
}
