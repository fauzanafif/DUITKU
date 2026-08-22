import 'package:duitku/core/utils/json_utils.dart';

/// A monthly spending limit for a single allowance account. Same shape as
/// [Budget] but scoped to an account instead of a category.
class AllowanceLimit {
  const AllowanceLimit({
    required this.id,
    required this.accountId,
    required this.limitAmount,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String accountId;
  final double limitAmount;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;

  AllowanceLimit copyWith({
    double? limitAmount,
    DateTime? updatedAt,
  }) {
    return AllowanceLimit(
      id: id,
      accountId: accountId,
      limitAmount: limitAmount ?? this.limitAmount,
      year: year,
      month: month,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'limitAmount': limitAmount,
        'year': year,
        'month': month,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AllowanceLimit.fromJson(Map<String, dynamic> json) =>
      AllowanceLimit(
        id: readString(json, 'id'),
        accountId: readString(json, 'accountId'),
        limitAmount: readDouble(json, 'limitAmount'),
        year: readInt(json, 'year', fallback: DateTime.now().year),
        month: readInt(json, 'month', fallback: DateTime.now().month),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
      );
}
