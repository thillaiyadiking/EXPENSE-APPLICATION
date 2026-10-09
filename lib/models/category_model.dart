import 'package:hive/hive.dart';

class CategoryModel extends HiveObject {
  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.isDefault = false,
    this.isIncome = false,
    this.sortOrder = 0,
  });

  final String id;
  String name;
  int iconCode;
  int colorValue;
  bool isDefault;
  bool isIncome;
  int sortOrder;

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    bool? isDefault,
    bool? isIncome,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      isIncome: isIncome ?? this.isIncome,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'isDefault': isDefault,
        'isIncome': isIncome,
        'sortOrder': sortOrder,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['iconCode'] as int,
      colorValue: json['colorValue'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconCode: fields[2] as int,
      colorValue: fields[3] as int,
      isDefault: fields[4] as bool? ?? false,
      isIncome: fields[5] as bool? ?? false,
      sortOrder: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconCode)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.isIncome)
      ..writeByte(6)
      ..write(obj.sortOrder);
  }
}
