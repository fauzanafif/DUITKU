import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

/// Single write entry point for the UI.
///
/// Widgets never touch repositories or the database directly; every mutation
/// goes through here so cache invalidation happens in exactly one place.
class FinanceController {
  FinanceController(this._ref);

  final Ref _ref;

  bool get _allowNegative =>
      _ref.read(settingsProvider).valueOrNull?.allowNegativeBalance ?? false;

  void _refresh() => invalidateFinancialData(_ref);

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    int? iconCodePoint,
    int? colorValue,
  }) async {
    final account = await _ref.read(accountRepositoryProvider).create(
          name: name,
          type: type,
          initialBalance: initialBalance,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        );
    _refresh();
    return account;
  }

  Future<void> saveAccount(Account account) async {
    await _ref.read(accountRepositoryProvider).save(account);
    _refresh();
  }

  Future<void> deleteAccount(String id) async {
    await _ref.read(accountRepositoryProvider).delete(id);
    _refresh();
  }

  Future<Account> ensureCashAccount() async {
    final account = await _ref.read(accountRepositoryProvider).ensureCashAccount();
    _refresh();
    return account;
  }

  Future<void> createCategory({
    required String name,
    required CategoryKind kind,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    await _ref.read(categoryRepositoryProvider).create(
          name: name,
          kind: kind,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        );
    _refresh();
  }

  Future<void> saveCategory(Category category) async {
    await _ref.read(categoryRepositoryProvider).save(category);
    _refresh();
  }

  Future<void> deleteCategory(String id, {String? reassignTo}) async {
    await _ref
        .read(categoryRepositoryProvider)
        .delete(id, reassignTo: reassignTo);
    _refresh();
  }

  Future<TransactionRecord> addTransaction(TransactionDraft draft) async {
    final record = await _ref
        .read(transactionRepositoryProvider)
        .add(draft, allowNegativeBalance: _allowNegative);
    _refresh();
    return record;
  }

  /// Convenience wrapper for the "Tarik Cash" shortcut. It reuses the exact
  /// same transfer logic, so a withdrawal is never treated as an expense.
  Future<TransactionRecord> withdrawCash({
    required String sourceAccountId,
    required String cashAccountId,
    required double amount,
    required DateTime transactionDateTime,
    String? note,
  }) {
    return addTransaction(
      TransactionDraft(
        type: TransactionType.transfer,
        title: 'Tarik Cash',
        amount: amount,
        accountId: sourceAccountId,
        destinationAccountId: cashAccountId,
        transactionDateTime: transactionDateTime,
        note: note,
      ),
    );
  }

  Future<TransactionRecord> updateTransaction(
    String id,
    TransactionDraft draft,
  ) async {
    final record = await _ref
        .read(transactionRepositoryProvider)
        .update(id, draft, allowNegativeBalance: _allowNegative);
    _refresh();
    return record;
  }

  Future<void> deleteTransaction(String id) async {
    await _ref.read(transactionRepositoryProvider).delete(id);
    _refresh();
  }

  Future<void> createBudget({
    required String categoryId,
    required double amount,
    required int year,
    required int month,
  }) async {
    await _ref.read(budgetRepositoryProvider).create(
          categoryId: categoryId,
          amount: amount,
          year: year,
          month: month,
        );
    _refresh();
  }

  Future<void> saveBudget(Budget budget) async {
    await _ref.read(budgetRepositoryProvider).save(budget);
    _refresh();
  }

  Future<void> deleteBudget(String id) async {
    await _ref.read(budgetRepositoryProvider).delete(id);
    _refresh();
  }

  Future<void> createSavingGoal({
    required String name,
    required double targetAmount,
    required int colorValue,
    required int iconCodePoint,
    DateTime? targetDate,
  }) async {
    await _ref.read(savingGoalRepositoryProvider).create(
          name: name,
          targetAmount: targetAmount,
          colorValue: colorValue,
          iconCodePoint: iconCodePoint,
          targetDate: targetDate,
        );
    _refresh();
  }

  Future<void> saveSavingGoal(SavingGoal goal) async {
    await _ref.read(savingGoalRepositoryProvider).save(goal);
    _refresh();
  }

  Future<void> deleteSavingGoal(String id) async {
    await _ref.read(savingGoalRepositoryProvider).delete(id);
    _refresh();
  }

  Future<void> addContribution(
    SavingGoal goal, {
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _ref.read(savingGoalRepositoryProvider).addContribution(
          goal,
          amount: amount,
          date: date,
          note: note,
        );
    _refresh();
  }

  Future<void> removeContribution(SavingGoal goal, String contributionId) async {
    await _ref
        .read(savingGoalRepositoryProvider)
        .removeContribution(goal, contributionId);
    _refresh();
  }
}

final financeControllerProvider =
    Provider<FinanceController>((ref) => FinanceController(ref));
