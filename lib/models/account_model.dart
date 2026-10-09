import 'package:hive/hive.dart';

enum AccountType { cash, bank, wallet, card }

class AccountModel extends HiveObject {
  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.colorValue = 0xFF0D9488,
    this.iconCode = 0xe53e, // Icons.account_balance_wallet
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  String name;
  AccountType type;
  double balance;
  int colorValue;
  int iconCode;
  bool isDefault;
  int sortOrder;

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    int? colorValue,
    int? iconCode,
    bool? isDefault,
    int? sortOrder,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'colorValue': colorValue,
        'iconCode': iconCode,
        'isDefault': isDefault,
        'sortOrder': sortOrder,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.byName(json['type'] as String),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      colorValue: json['colorValue'] as int? ?? 0xFF0D9488,
      iconCode: json['iconCode'] as int? ?? 0xe53e,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

}

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 3;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: AccountType.values[fields[2] as int],
      balance: fields[3] as double? ?? 0,
      colorValue: fields[4] as int? ?? 0xFF0D9488,
      iconCode: fields[5] as int? ?? 0xe53e,
      isDefault: fields[6] as bool? ?? false,
      sortOrder: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.iconCode)
      ..writeByte(6)
      ..write(obj.isDefault)
      ..writeByte(7)
      ..write(obj.sortOrder);
  }
}
