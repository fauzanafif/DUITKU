import 'package:duitku/core/utils/json_utils.dart';
import 'package:duitku/data/models/transaction.dart';

enum RecurringInterval { daily, weekly, monthly, yearly }

extension RecurringIntervalLabel on RecurringInterval {
  String get label {
    switch (this) {
      case RecurringInterval.daily:
        return 'Hari';
      case RecurringInterval.weekly:
        return 'Minggu';
      case RecurringInterval.monthly:
        return 'Bulan';
      case RecurringInterval.yearly:
        return 'Tahun';
    }
  }
}

/// A recurring transaction template (subscription, routine bill, regular
/// income, ...). The app never books a transaction on its own — a due rule
/// only ever becomes a transaction when the user explicitly confirms it, so
/// nothing ever appears in the ledger unannounced.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.intervalUnit,
    required this.intervalCount,
    required this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.lastGeneratedDate,
    this.isActive = true,
  });

  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String accountId;
  final String? categoryId;
  final RecurringInterval intervalUnit;
  final int intervalCount;
  final DateTime nextDueDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDue =>
      isActive && !nextDueDate.isAfter(DateTime.now());

  /// The occurrence after [nextDueDate], following [intervalUnit] /
  /// [intervalCount]. Month/year math clamps to a valid calendar date
  /// (Dart's [DateTime] constructor already rolls a day-31 add into the
  /// next month correctly for shorter months).
  DateTime advancedDueDate() {
    switch (intervalUnit) {
      case RecurringInterval.daily:
        return nextDueDate.add(Duration(days: intervalCount));
      case RecurringInterval.weekly:
        return nextDueDate.add(Duration(days: 7 * intervalCount));
      case RecurringInterval.monthly:
        return DateTime(
          nextDueDate.year,
          nextDueDate.month + intervalCount,
          nextDueDate.day,
          nextDueDate.hour,
          nextDueDate.minute,
        );
      case RecurringInterval.yearly:
        return DateTime(
          nextDueDate.year + intervalCount,
          nextDueDate.month,
          nextDueDate.day,
          nextDueDate.hour,
          nextDueDate.minute,
        );
    }
  }

  RecurringRule copyWith({
    String? title,
    TransactionType? type,
    double? amount,
    String? accountId,
    Object? categoryId = _unset,
    RecurringInterval? intervalUnit,
    int? intervalCount,
    DateTime? nextDueDate,
    Object? lastGeneratedDate = _unset,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RecurringRule(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId:
          categoryId == _unset ? this.categoryId : categoryId as String?,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      intervalCount: intervalCount ?? this.intervalCount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: lastGeneratedDate == _unset
          ? this.lastGeneratedDate
          : lastGeneratedDate as DateTime?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'categoryId': categoryId,
        'intervalUnit': intervalUnit.name,
        'intervalCount': intervalCount,
        'nextDueDate': nextDueDate.toIso8601String(),
        'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RecurringRule.fromJson(Map<String, dynamic> json) => RecurringRule(
        id: readString(json, 'id'),
        title: readString(json, 'title'),
        type: readEnum(
            json, 'type', TransactionType.values, TransactionType.expense),
        amount: readDouble(json, 'amount'),
        accountId: readString(json, 'accountId'),
        categoryId: readNullableString(json, 'categoryId'),
        intervalUnit: readEnum(json, 'intervalUnit', RecurringInterval.values,
            RecurringInterval.monthly),
        intervalCount: readInt(json, 'intervalCount', fallback: 1),
        nextDueDate: readDate(json, 'nextDueDate'),
        lastGeneratedDate: json['lastGeneratedDate'] is String
            ? DateTime.tryParse(json['lastGeneratedDate'] as String)
            : null,
        isActive: readBool(json, 'isActive', fallback: true),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
      );
}

const Object _unset = Object();
