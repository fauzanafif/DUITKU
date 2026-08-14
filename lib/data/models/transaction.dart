import 'package:duitku/core/utils/json_utils.dart';

enum TransactionType { income, expense, transfer }

extension TransactionTypeLabel on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

/// A single financial event.
///
/// Account balances are always derived from the transaction list
/// (see `FinanceCalculator`), never stored on the account itself, so editing
/// or deleting a transaction can never double count.
class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.accountId,
    required this.transactionDateTime,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.destinationAccountId,
    this.note,
    this.paymentMethod,
    this.savingGoalId,
  });

  final String id;
  final TransactionType type;
  final String title;
  final double amount;

  /// Destination account for income, source account for expense and transfer.
  final String accountId;

  /// Only set for [TransactionType.transfer].
  final String? destinationAccountId;
  final String? categoryId;

  /// The moment the money actually moved. All reporting uses this field.
  final DateTime transactionDateTime;
  final String? note;
  final String? paymentMethod;

  /// Set when the transaction is a contribution to a saving goal.
  final String? savingGoalId;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTransfer => type == TransactionType.transfer;

  TransactionRecord copyWith({
    TransactionType? type,
    String? title,
    double? amount,
    String? accountId,
    Object? destinationAccountId = _unset,
    Object? categoryId = _unset,
    DateTime? transactionDateTime,
    Object? note = _unset,
    Object? paymentMethod = _unset,
    Object? savingGoalId = _unset,
    DateTime? updatedAt,
  }) {
    return TransactionRecord(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId == _unset
          ? this.destinationAccountId
          : destinationAccountId as String?,
      categoryId:
          categoryId == _unset ? this.categoryId : categoryId as String?,
      transactionDateTime: transactionDateTime ?? this.transactionDateTime,
      note: note == _unset ? this.note : note as String?,
      paymentMethod: paymentMethod == _unset
          ? this.paymentMethod
          : paymentMethod as String?,
      savingGoalId:
          savingGoalId == _unset ? this.savingGoalId : savingGoalId as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'amount': amount,
        'accountId': accountId,
        'destinationAccountId': destinationAccountId,
        'categoryId': categoryId,
        'transactionDateTime': transactionDateTime.toIso8601String(),
        'note': note,
        'paymentMethod': paymentMethod,
        'savingGoalId': savingGoalId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: readString(json, 'id'),
      type: readEnum(
          json, 'type', TransactionType.values, TransactionType.expense),
      title: readString(json, 'title', fallback: '-'),
      amount: readDouble(json, 'amount'),
      accountId: readString(json, 'accountId'),
      destinationAccountId: readNullableString(json, 'destinationAccountId'),
      categoryId: readNullableString(json, 'categoryId'),
      transactionDateTime: readDate(json, 'transactionDateTime'),
      note: readNullableString(json, 'note'),
      paymentMethod: readNullableString(json, 'paymentMethod'),
      savingGoalId: readNullableString(json, 'savingGoalId'),
      createdAt: readDate(json, 'createdAt'),
      updatedAt: readDate(json, 'updatedAt'),
    );
  }
}

const Object _unset = Object();
