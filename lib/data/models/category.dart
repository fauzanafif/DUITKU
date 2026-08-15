import 'package:duitku/core/utils/json_utils.dart';

enum CategoryKind { income, expense }

extension CategoryKindLabel on CategoryKind {
  String get label =>
      this == CategoryKind.income ? 'Pemasukan' : 'Pengeluaran';
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  Category copyWith({
    String? name,
    CategoryKind? kind,
    int? iconCodePoint,
    int? colorValue,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: readString(json, 'id'),
        name: readString(json, 'name'),
        kind: readEnum(json, 'kind', CategoryKind.values, CategoryKind.expense),
        iconCodePoint: readInt(json, 'iconCodePoint', fallback: 0xe25a),
        colorValue: readInt(json, 'colorValue', fallback: 0xff2563eb),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
        isDefault: readBool(json, 'isDefault'),
      );
}
