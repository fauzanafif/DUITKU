import 'package:duitku/core/utils/json_utils.dart';

/// A monthly spending limit for a single expense category.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final double amount;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get periodStart => DateTime(year, month);
  DateTime get periodEnd => DateTime(year, month + 1);

  Budget copyWith({
    String? categoryId,
    double? amount,
    int? year,
    int? month,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'year': year,
        'month': month,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: readString(json, 'id'),
        categoryId: readString(json, 'categoryId'),
        amount: readDouble(json, 'amount'),
        year: readInt(json, 'year', fallback: DateTime.now().year),
        month: readInt(json, 'month', fallback: DateTime.now().month),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
      );
}
