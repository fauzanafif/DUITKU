import 'package:duitku/core/finance/transaction_validator.dart';
import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.title,
    required this.amount,
    required this.accountId,
    required this.transactionDateTime,
    this.categoryId,
    this.destinationAccountId,
    this.note,
    this.paymentMethod,
    this.savingGoalId,
    this.debtId,
  });

  final TransactionType type;
  final String title;
  final double amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final DateTime transactionDateTime;
  final String? note;
  final String? paymentMethod;
  final String? savingGoalId;
  final String? debtId;
}

class TransactionRepository {
  TransactionRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<TransactionRecord>> getAll() async {
    final transactions = await _db.readTransactions();
    transactions
        .sort((a, b) => b.transactionDateTime.compareTo(a.transactionDateTime));
    return transactions;
  }

  Future<TransactionRecord?> findById(String id) async {
    final transactions = await _db.readTransactions();
    for (final tx in transactions) {
      if (tx.id == id) return tx;
    }
    return null;
  }

  Future<TransactionRecord> add(
    TransactionDraft draft, {
    bool allowNegativeBalance = false,
  }) async {
    final now = DateTime.now();
    final record = TransactionRecord(
      id: _uuid.v4(),
      type: draft.type,
      title: draft.title.trim(),
      amount: draft.amount,
      accountId: draft.accountId,
      destinationAccountId: draft.type == TransactionType.transfer
          ? draft.destinationAccountId
          : null,
      categoryId:
          draft.type == TransactionType.transfer ? null : draft.categoryId,
      transactionDateTime: draft.transactionDateTime,
      note: draft.note,
      paymentMethod: draft.paymentMethod,
      savingGoalId: draft.savingGoalId,
      debtId: draft.debtId,
      createdAt: now,
      updatedAt: now,
    );
    await _validate(record, allowNegativeBalance: allowNegativeBalance);
    await _db.writeTransaction(record);
    return record;
  }

  /// Updating rewrites the stored record. Because balances are derived from
  /// the transaction list, the previous effect disappears automatically and
  /// no amount can ever be counted twice.
  Future<TransactionRecord> update(
    String id,
    TransactionDraft draft, {
    bool allowNegativeBalance = false,
  }) async {
    final existing = await findById(id);
    if (existing == null) {
      throw StateError('Transaksi tidak ditemukan.');
    }
    final updated = existing.copyWith(
      type: draft.type,
      title: draft.title.trim(),
      amount: draft.amount,
      accountId: draft.accountId,
      destinationAccountId: draft.type == TransactionType.transfer
          ? draft.destinationAccountId
          : null,
      categoryId:
          draft.type == TransactionType.transfer ? null : draft.categoryId,
      transactionDateTime: draft.transactionDateTime,
      note: draft.note,
      paymentMethod: draft.paymentMethod,
      savingGoalId: draft.savingGoalId,
      debtId: draft.debtId,
      updatedAt: DateTime.now(),
    );
    await _validate(updated, allowNegativeBalance: allowNegativeBalance);
    await _db.writeTransaction(updated);
    return updated;
  }

  Future<void> delete(String id) => _db.deleteTransaction(id);

  Future<void> deleteBySavingGoal(String goalId) async {
    final transactions = await _db.readTransactions();
    for (final tx in transactions.where((tx) => tx.savingGoalId == goalId)) {
      await _db.deleteTransaction(tx.id);
    }
  }

  /// Detaches payment history from a deleted/archived debt without deleting
  /// the transactions themselves — they remain real spending history.
  Future<void> unlinkDebt(String debtId) async {
    final transactions = await _db.readTransactions();
    for (final tx in transactions.where((tx) => tx.debtId == debtId)) {
      await _db.writeTransaction(tx.copyWith(debtId: null));
    }
  }

  Future<void> _validate(
    TransactionRecord record, {
    required bool allowNegativeBalance,
  }) async {
    final accounts = await _db.readAccounts();
    final others = (await _db.readTransactions())
        .where((tx) => tx.id != record.id)
        .toList();
    final error = TransactionValidator.validate(
      draft: record,
      accounts: accounts,
      existingTransactions: others,
      allowNegativeBalance: allowNegativeBalance,
    );
    if (error != null) throw ValidationFailure(error);
  }
}
