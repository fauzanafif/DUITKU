import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';

/// Everything the read-only screens need, resolved once and shared.
class FinanceSnapshot {
  FinanceSnapshot({
    required this.accounts,
    required this.categories,
    required this.transactions,
  })  : accountsById = {for (final a in accounts) a.id: a},
        categoriesById = {for (final c in categories) c.id: c},
        balances = FinanceCalculator.balancesByAccount(accounts, transactions);

  final List<Account> accounts;
  final List<Category> categories;
  final List<TransactionRecord> transactions;
  final Map<String, Account> accountsById;
  final Map<String, Category> categoriesById;
  final Map<String, double> balances;

  double balanceOf(String accountId) => balances[accountId] ?? 0;

  double get totalBalance =>
      accounts.fold<double>(0, (sum, a) => sum + balanceOf(a.id));

  Account? get cashAccount {
    for (final account in accounts) {
      if (account.type == AccountType.cash) return account;
    }
    return null;
  }

  List<Category> categoriesOf(CategoryKind kind) =>
      categories.where((c) => c.kind == kind).toList();
}

final financeSnapshotProvider = FutureProvider<FinanceSnapshot>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  return FinanceSnapshot(
    accounts: accounts,
    categories: categories,
    transactions: transactions,
  );
});
