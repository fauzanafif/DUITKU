import 'package:duitku/core/utils/json_utils.dart';

enum AccountType { bank, cash, ewallet, other }

extension AccountTypeLabel on AccountType {
  String get label {
    switch (this) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.cash:
        return 'Cash';
      case AccountType.ewallet:
        return 'E-Wallet';
      case AccountType.other:
        return 'Lainnya';
    }
  }
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  bool get isCash => type == AccountType.cash;

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    int? iconCodePoint,
    int? colorValue,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: readString(json, 'id'),
        name: readString(json, 'name'),
        type: readEnum(json, 'type', AccountType.values, AccountType.other),
        initialBalance: readDouble(json, 'initialBalance'),
        iconCodePoint: readInt(json, 'iconCodePoint', fallback: 0xe263),
        colorValue: readInt(json, 'colorValue', fallback: 0xff2563eb),
        createdAt: readDate(json, 'createdAt'),
        updatedAt: readDate(json, 'updatedAt'),
        archived: readBool(json, 'archived'),
      );
}
