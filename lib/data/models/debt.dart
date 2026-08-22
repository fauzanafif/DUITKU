import 'package:duitku/core/utils/json_utils.dart';

enum DebtType { installment, creditCard, paylater }

extension DebtTypeLabel on DebtType {
  String get label {
    switch (this) {
      case DebtType.installment:
        return 'Cicilan';
      case DebtType.creditCard:
        return 'Kartu Kredit';
      case DebtType.paylater:
        return 'Paylater';
    }
  }
}

/// A debt, installment or paylater plan tracked outside the normal
/// account balances. Payments against it are booked as ordinary expense
/// transactions (linked via `TransactionRecord.debtId`) so they flow
/// through reports, insights and the health score for free.
class Debt {
  const Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.remainingAmount,
    required this.dueDay,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.totalAmount,
    this.installmentAmount,
    this.startDate,
    this.accountId,
    this.isSettled = false,
    this.reminderEnabled = false,
  });

  final String id;
  final String name;
  final DebtType type;

  /// Remaining balance still owed. Never stored as negative.
  final double remainingAmount;

  /// The original amount borrowed, if known.
  final double? totalAmount;

  /// The usual monthly installment, if known.
  final double? installmentAmount;

  /// Day of the month (1-31) the payment is due.
  final int dueDay;

  final DateTime? startDate;

  /// Default account payments are made from.
  final String? accountId;

  final int colorValue;
  final int iconCodePoint;
  final bool isSettled;

  /// Whether a due-date reminder notification should be scheduled.
  final bool reminderEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress => totalAmount == null || totalAmount == 0
      ? 0
      : (1 - (remainingAmount / totalAmount!)).clamp(0.0, 1.0);

  Debt copyWith({
    String? name,
    DebtType? type,
    double? remainingAmount,
    Object? totalAmount = _unset,
    Object? installmentAmount = _unset,
    int? dueDay,
    Object? startDate = _unset,
    Object? accountId = _unset,
    int? colorValue,
    int? iconCodePoint,
    bool? isSettled,
    bool? reminderEnabled,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      totalAmount:
          totalAmount == _unset ? this.totalAmount : totalAmount as double?,
      installmentAmount: installmentAmount == _unset
          ? this.installmentAmount
          : installmentAmount as double?,
      dueDay: dueDay ?? this.dueDay,
      startDate: startDate == _unset ? this.startDate : startDate as DateTime?,
      accountId: accountId == _unset ? this.accountId : accountId as String?,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isSettled: isSettled ?? this.isSettled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'remainingAmount': remainingAmount,
        'totalAmount': totalAmount,
        'installmentAmount': installmentAmount,
        'dueDay': dueDay,
        'startDate': startDate?.toIso8601String(),
        'accountId': accountId,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'isSettled': isSettled,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: readString(json, 'id'),
        name: readString(json, 'name'),
        type: readEnum(json, 'type', DebtType.values, DebtType.installment),
        remainingAmount: readDouble(json, 'remainingAmount'),
        totalAmount: json['totalAmount'] == null
            ? null
            : readDouble(json, 'totalAmount'),
        installmentAmount: json['installmentAmount'] == null
            ? null
            : readDouble(json, 'installmentAmount'),
        dueDay: readInt(json, 'dueDay', fallback: 1).clamp(1, 31),
        startDate: json['startDate'] is String
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        accountId: readNullableString(json, 'accountId'),
        colorValue: readInt(json, 'colorValue', fallback: 0xff2563eb),
        iconCodePoint: readInt(json, 'iconCodePoint', fallback: 0xe870),
        isSettled: readBool(json, 'isSettled'),
        reminderEnabled: readBool(json, 'reminderEnabled'),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
      );
}

const Object _unset = Object();
