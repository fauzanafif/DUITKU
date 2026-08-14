import 'package:duitku/core/utils/json_utils.dart';

class SavingContribution {
  const SavingContribution({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory SavingContribution.fromJson(Map<String, dynamic> json) =>
      SavingContribution(
        id: readString(json, 'id'),
        amount: readDouble(json, 'amount'),
        date: readDate(json, 'date'),
        note: readNullableString(json, 'note'),
      );
}

class SavingGoal {
  const SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.contributions,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
  });

  final String id;
  final String name;
  final double targetAmount;
  final List<SavingContribution> contributions;
  final int colorValue;
  final int iconCodePoint;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get currentAmount =>
      contributions.fold<double>(0, (sum, item) => sum + item.amount);

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  double get remaining =>
      (targetAmount - currentAmount) < 0 ? 0 : targetAmount - currentAmount;

  SavingGoal copyWith({
    String? name,
    double? targetAmount,
    List<SavingContribution>? contributions,
    int? colorValue,
    int? iconCodePoint,
    Object? targetDate = _unset,
    DateTime? updatedAt,
  }) {
    return SavingGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      contributions: contributions ?? this.contributions,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      targetDate:
          targetDate == _unset ? this.targetDate : targetDate as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'contributions': contributions.map((e) => e.toJson()).toList(),
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'targetDate': targetDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final rawContributions = json['contributions'];
    return SavingGoal(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      targetAmount: readDouble(json, 'targetAmount'),
      contributions: rawContributions is List
          ? rawContributions
              .whereType<Map>()
              .map((e) =>
                  SavingContribution.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <SavingContribution>[],
      colorValue: readInt(json, 'colorValue', fallback: 0xff2563eb),
      iconCodePoint: readInt(json, 'iconCodePoint', fallback: 0xe263),
      targetDate: json['targetDate'] is String
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      createdAt: readDate(json, 'createdAt'),
      updatedAt: readDate(json, 'updatedAt'),
    );
  }
}

const Object _unset = Object();
