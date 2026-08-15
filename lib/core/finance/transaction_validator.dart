import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/transaction.dart';

class ValidationFailure implements Exception {
  ValidationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class TransactionValidator {
  const TransactionValidator._();

  /// Returns an error message, or null when the draft is valid.
  ///
  /// [existingTransactions] must already exclude the transaction being edited
  /// so the balance check does not count the old version twice.
  static String? validate({
    required TransactionRecord draft,
    required List<Account> accounts,
    required List<TransactionRecord> existingTransactions,
    bool allowNegativeBalance = false,
  }) {
    if (draft.amount <= 0) {
      return 'Nominal harus lebih besar dari nol.';
    }
    final source = _findAccount(accounts, draft.accountId);
    if (source == null) {
      return 'Akun tidak ditemukan.';
    }
    if (draft.type == TransactionType.transfer) {
      final destinationId = draft.destinationAccountId;
      if (destinationId == null || destinationId.isEmpty) {
        return 'Akun tujuan wajib dipilih.';
      }
      if (destinationId == draft.accountId) {
        return 'Akun asal dan tujuan tidak boleh sama.';
      }
      if (_findAccount(accounts, destinationId) == null) {
        return 'Akun tujuan tidak ditemukan.';
      }
    } else if (draft.categoryId == null || draft.categoryId!.isEmpty) {
      return 'Kategori wajib dipilih.';
    }

    final spendsFromSource = draft.type == TransactionType.expense ||
        draft.type == TransactionType.transfer;
    if (!allowNegativeBalance && spendsFromSource) {
      final available =
          FinanceCalculator.accountBalance(source, existingTransactions);
      if (available < draft.amount) {
        return 'Saldo ${source.name} tidak mencukupi.';
      }
    }
    return null;
  }

  static Account? _findAccount(List<Account> accounts, String id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }
}
