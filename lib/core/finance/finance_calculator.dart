import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/transaction.dart';

class CategoryBreakdownEntry {
  const CategoryBreakdownEntry({
    required this.categoryId,
    required this.total,
    required this.share,
  });

  final String? categoryId;
  final double total;

  /// Fraction of the period total, 0..1.
  final double share;
}

class BudgetStatus {
  const BudgetStatus({
    required this.budget,
    required this.used,
  });

  final Budget budget;
  final double used;

  double get remaining => budget.amount - used;
  double get ratio => budget.amount <= 0 ? 0 : used / budget.amount;
  bool get isOverBudget => ratio >= 1;
  bool get isCritical => ratio >= 0.9 && ratio < 1;
  bool get isWarning => ratio >= 0.8 && ratio < 0.9;
}

class CashFlowSummary {
  const CashFlowSummary({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get net => income - expense;
}

/// All money math lives here.
///
/// Balances are always derived from the transaction list, so creating,
/// editing and deleting transactions can never leave a stale balance behind.
class FinanceCalculator {
  const FinanceCalculator._();

  /// Effect of a single transaction on one account.
  static double effectOnAccount(TransactionRecord tx, String accountId) {
    switch (tx.type) {
      case TransactionType.income:
        return tx.accountId == accountId ? tx.amount : 0;
      case TransactionType.expense:
        return tx.accountId == accountId ? -tx.amount : 0;
      case TransactionType.transfer:
        var delta = 0.0;
        if (tx.accountId == accountId) delta -= tx.amount;
        if (tx.destinationAccountId == accountId) delta += tx.amount;
        return delta;
    }
  }

  static double accountBalance(
    Account account,
    Iterable<TransactionRecord> transactions,
  ) {
    var balance = account.initialBalance;
    for (final tx in transactions) {
      balance += effectOnAccount(tx, account.id);
    }
    return balance;
  }

  static Map<String, double> balancesByAccount(
    Iterable<Account> accounts,
    Iterable<TransactionRecord> transactions,
  ) {
    final balances = <String, double>{
      for (final account in accounts) account.id: account.initialBalance,
    };
    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          balances.update(tx.accountId, (value) => value + tx.amount,
              ifAbsent: () => tx.amount);
        case TransactionType.expense:
          balances.update(tx.accountId, (value) => value - tx.amount,
              ifAbsent: () => -tx.amount);
        case TransactionType.transfer:
          balances.update(tx.accountId, (value) => value - tx.amount,
              ifAbsent: () => -tx.amount);
          final destination = tx.destinationAccountId;
          if (destination != null) {
            balances.update(destination, (value) => value + tx.amount,
                ifAbsent: () => tx.amount);
          }
      }
    }
    return balances;
  }

  static double totalBalance(
    Iterable<Account> accounts,
    Iterable<TransactionRecord> transactions,
  ) {
    final balances = balancesByAccount(accounts, transactions);
    return accounts.fold<double>(0, (sum, a) => sum + (balances[a.id] ?? 0));
  }

  static Iterable<TransactionRecord> inRange(
    Iterable<TransactionRecord> transactions,
    DateRange range,
  ) =>
      transactions.where((tx) => range.contains(tx.transactionDateTime));

  /// Transfers are deliberately excluded from income and expense totals.
  static double totalIncome(
    Iterable<TransactionRecord> transactions,
    DateRange range,
  ) =>
      inRange(transactions, range)
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

  static double totalExpense(
    Iterable<TransactionRecord> transactions,
    DateRange range,
  ) =>
      inRange(transactions, range)
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

  static double totalTransfer(
    Iterable<TransactionRecord> transactions,
    DateRange range,
  ) =>
      inRange(transactions, range)
          .where((tx) => tx.type == TransactionType.transfer)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

  static CashFlowSummary cashFlow(
    Iterable<TransactionRecord> transactions,
    DateRange range,
  ) =>
      CashFlowSummary(
        income: totalIncome(transactions, range),
        expense: totalExpense(transactions, range),
      );

  static List<CategoryBreakdownEntry> breakdownByCategory(
    Iterable<TransactionRecord> transactions,
    DateRange range, {
    TransactionType type = TransactionType.expense,
  }) {
    final totals = <String?, double>{};
    for (final tx in inRange(transactions, range)) {
      if (tx.type != type) continue;
      totals.update(tx.categoryId, (value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }
    final grandTotal = totals.values.fold<double>(0, (sum, v) => sum + v);
    final entries = totals.entries
        .map((entry) => CategoryBreakdownEntry(
              categoryId: entry.key,
              total: entry.value,
              share: grandTotal == 0 ? 0 : entry.value / grandTotal,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return entries;
  }

  /// Money flowing into an account, excluding internal transfers when
  /// [includeTransfers] is false.
  static double inflow(
    Iterable<TransactionRecord> transactions,
    String accountId,
    DateRange range, {
    bool includeTransfers = true,
  }) {
    var total = 0.0;
    for (final tx in inRange(transactions, range)) {
      if (tx.type == TransactionType.income && tx.accountId == accountId) {
        total += tx.amount;
      } else if (includeTransfers &&
          tx.type == TransactionType.transfer &&
          tx.destinationAccountId == accountId) {
        total += tx.amount;
      }
    }
    return total;
  }

  static double outflow(
    Iterable<TransactionRecord> transactions,
    String accountId,
    DateRange range, {
    bool includeTransfers = true,
  }) {
    var total = 0.0;
    for (final tx in inRange(transactions, range)) {
      if (tx.type == TransactionType.expense && tx.accountId == accountId) {
        total += tx.amount;
      } else if (includeTransfers &&
          tx.type == TransactionType.transfer &&
          tx.accountId == accountId) {
        total += tx.amount;
      }
    }
    return total;
  }

  /// Budgets only ever consider expense transactions of the category.
  static BudgetStatus budgetStatus(
    Budget budget,
    Iterable<TransactionRecord> transactions, {
    int payday = 1,
  }) {
    final range =
        DateRange.financialMonth(budget.year, budget.month, payday);
    final used = inRange(transactions, range)
        .where((tx) =>
            tx.type == TransactionType.expense &&
            tx.categoryId == budget.categoryId)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    return BudgetStatus(budget: budget, used: used);
  }

  static Map<DateTime, List<TransactionRecord>> groupByDay(
    Iterable<TransactionRecord> transactions,
  ) {
    final sorted = transactions.toList()
      ..sort((a, b) => b.transactionDateTime.compareTo(a.transactionDateTime));
    final grouped = <DateTime, List<TransactionRecord>>{};
    for (final tx in sorted) {
      final day = DateTime(
        tx.transactionDateTime.year,
        tx.transactionDateTime.month,
        tx.transactionDateTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(tx);
    }
    return grouped;
  }
}
