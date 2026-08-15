import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:uuid/uuid.dart';

class AccountRepository {
  AccountRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<Account>> getAll() async {
    final accounts = await _db.readAccounts();
    accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return accounts;
  }

  Future<Account> create({
    required String name,
    required AccountType type,
    required double initialBalance,
    int? iconCodePoint,
    int? colorValue,
  }) async {
    final now = DateTime.now();
    final account = Account(
      id: _uuid.v4(),
      name: name.trim(),
      type: type,
      initialBalance: initialBalance,
      iconCodePoint: iconCodePoint ??
          (AppDefaults.accountTypeIcons[type] ?? AppDefaults.iconChoices.first)
              .codePoint,
      colorValue: colorValue ?? AppDefaults.palette.first.toARGB32(),
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeAccount(account);
    return account;
  }

  Future<void> save(Account account) => _db.writeAccount(account);

  /// Accounts referenced by a transaction cannot be removed, otherwise the
  /// derived balances would silently lose money.
  Future<void> delete(String id) async {
    final transactions = await _db.readTransactions();
    final referenced = transactions.any(
      (tx) => tx.accountId == id || tx.destinationAccountId == id,
    );
    if (referenced) {
      throw StateError(
        'Akun masih dipakai transaksi. Hapus atau pindahkan transaksinya dulu.',
      );
    }
    await _db.deleteAccount(id);
  }

  Future<Account?> findCashAccount() async {
    final accounts = await getAll();
    for (final account in accounts) {
      if (account.type == AccountType.cash) return account;
    }
    return null;
  }

  /// Guarantees a cash account exists so "Tarik Cash" always has a target.
  Future<Account> ensureCashAccount() async {
    final existing = await findCashAccount();
    if (existing != null) return existing;
    return create(
      name: AppDefaults.cashAccountName,
      type: AccountType.cash,
      initialBalance: 0,
      colorValue: AppDefaults.palette[1].toARGB32(),
    );
  }

  Future<bool> isReferenced(String accountId) async {
    final transactions = await _db.readTransactions();
    return transactions.any((TransactionRecord tx) =>
        tx.accountId == accountId || tx.destinationAccountId == accountId);
  }
}
