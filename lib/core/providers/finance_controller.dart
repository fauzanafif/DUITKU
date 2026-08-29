import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
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

  /// Appends one audit-trail entry. Called after a mutation succeeds, so a
  /// failed operation (e.g. deleting a still-referenced account) never logs.
  Future<void> _log({
    required LogModule module,
    required LogAction action,
    required String entityName,
    String? detail,
  }) {
    return _ref.read(activityLogRepositoryProvider).add(
          module: module,
          action: action,
          entityName: entityName,
          detail: detail,
        );
  }

  String _money(double value) => Formatters.currency(value);

  String _diff(String before, String after) => '$before → $after';

  Future<String> _categoryName(String? categoryId) async {
    if (categoryId == null) return 'Kategori';
    final categories = await _ref.read(categoryRepositoryProvider).getAll();
    return categories.firstWhereOrNull((c) => c.id == categoryId)?.name ??
        'Kategori';
  }

  /// Transactions are logged under their category name (matching the user's
  /// example `UPDATE | Transaksi | Makanan`); transfers have no category so
  /// they fall back to the transaction title.
  Future<String> _transactionEntityName(TransactionRecord record) async {
    final categoryId = record.categoryId;
    if (categoryId == null) return record.title;
    final categories = await _ref.read(categoryRepositoryProvider).getAll();
    return categories.firstWhereOrNull((c) => c.id == categoryId)?.name ??
        record.title;
  }

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
    await _log(
      module: LogModule.rekening,
      action: LogAction.create,
      entityName: account.name,
      detail: 'Saldo awal ${_money(account.initialBalance)}',
    );
    _refresh();
    return account;
  }

  Future<void> saveAccount(Account account) async {
    final before = (await _ref.read(accountRepositoryProvider).getAll())
        .firstWhereOrNull((a) => a.id == account.id);
    await _ref.read(accountRepositoryProvider).save(account);
    await _log(
      module: LogModule.rekening,
      action: LogAction.update,
      entityName: account.name,
      detail: _accountDiff(before, account),
    );
    _refresh();
  }

  String? _accountDiff(Account? before, Account after) {
    if (before == null) return null;
    final parts = <String>[];
    if (before.name != after.name) {
      parts.add(_diff('"${before.name}"', '"${after.name}"'));
    }
    if (before.initialBalance != after.initialBalance) {
      parts.add(_diff(
          _money(before.initialBalance), _money(after.initialBalance)));
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> deleteAccount(String id) async {
    final target = (await _ref.read(accountRepositoryProvider).getAll())
        .firstWhereOrNull((a) => a.id == id);
    await _ref.read(accountRepositoryProvider).delete(id);
    await _log(
      module: LogModule.rekening,
      action: LogAction.delete,
      entityName: target?.name ?? 'Rekening',
    );
    _refresh();
  }

  Future<Account> ensureCashAccount() async {
    final account = await _ref.read(accountRepositoryProvider).ensureCashAccount();
    _refresh();
    return account;
  }

  Future<Category> createCategory({
    required String name,
    required CategoryKind kind,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final category = await _ref.read(categoryRepositoryProvider).create(
          name: name,
          kind: kind,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        );
    await _log(
      module: LogModule.kategori,
      action: LogAction.create,
      entityName: category.name,
    );
    _refresh();
    return category;
  }

  Future<void> saveCategory(Category category) async {
    final before = (await _ref.read(categoryRepositoryProvider).getAll())
        .firstWhereOrNull((c) => c.id == category.id);
    await _ref.read(categoryRepositoryProvider).save(category);
    await _log(
      module: LogModule.kategori,
      action: LogAction.update,
      entityName: category.name,
      detail: before != null && before.name != category.name
          ? _diff('"${before.name}"', '"${category.name}"')
          : null,
    );
    _refresh();
  }

  Future<void> deleteCategory(String id, {String? reassignTo}) async {
    final target = (await _ref.read(categoryRepositoryProvider).getAll())
        .firstWhereOrNull((c) => c.id == id);
    await _ref
        .read(categoryRepositoryProvider)
        .delete(id, reassignTo: reassignTo);
    await _log(
      module: LogModule.kategori,
      action: LogAction.delete,
      entityName: target?.name ?? 'Kategori',
    );
    _refresh();
  }

  Future<TransactionRecord> addTransaction(TransactionDraft draft) async {
    final record = await _ref
        .read(transactionRepositoryProvider)
        .add(draft, allowNegativeBalance: _allowNegative);
    await _log(
      module: LogModule.transaksi,
      action: LogAction.create,
      entityName: await _transactionEntityName(record),
      detail: _money(record.amount),
    );
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
    final before =
        await _ref.read(transactionRepositoryProvider).findById(id);
    final record = await _ref
        .read(transactionRepositoryProvider)
        .update(id, draft, allowNegativeBalance: _allowNegative);
    await _log(
      module: LogModule.transaksi,
      action: LogAction.update,
      entityName: await _transactionEntityName(record),
      detail: before != null && before.amount != record.amount
          ? _diff(_money(before.amount), _money(record.amount))
          : null,
    );
    _refresh();
    return record;
  }

  Future<void> deleteTransaction(String id) async {
    final target =
        await _ref.read(transactionRepositoryProvider).findById(id);
    await _ref.read(transactionRepositoryProvider).delete(id);
    await _log(
      module: LogModule.transaksi,
      action: LogAction.delete,
      entityName: target != null
          ? await _transactionEntityName(target)
          : 'Transaksi',
      detail: target != null ? _money(target.amount) : null,
    );
    _refresh();
  }

  Future<void> createBudget({
    required String categoryId,
    required double amount,
    required int year,
    required int month,
  }) async {
    final budget = await _ref.read(budgetRepositoryProvider).create(
          categoryId: categoryId,
          amount: amount,
          year: year,
          month: month,
        );
    await _log(
      module: LogModule.budget,
      action: LogAction.create,
      entityName: await _categoryName(budget.categoryId),
      detail: _money(budget.amount),
    );
    _refresh();
  }

  Future<void> saveBudget(Budget budget) async {
    final before = (await _ref.read(budgetRepositoryProvider).getAll())
        .firstWhereOrNull((b) => b.id == budget.id);
    await _ref.read(budgetRepositoryProvider).save(budget);
    await _log(
      module: LogModule.budget,
      action: LogAction.update,
      entityName: await _categoryName(budget.categoryId),
      detail: before != null && before.amount != budget.amount
          ? _diff(_money(before.amount), _money(budget.amount))
          : null,
    );
    _refresh();
  }

  Future<void> deleteBudget(String id) async {
    final target = (await _ref.read(budgetRepositoryProvider).getAll())
        .firstWhereOrNull((b) => b.id == id);
    await _ref.read(budgetRepositoryProvider).delete(id);
    await _log(
      module: LogModule.budget,
      action: LogAction.delete,
      entityName:
          target != null ? await _categoryName(target.categoryId) : 'Budget',
    );
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

  Future<Debt> createDebt({
    required String name,
    required DebtType type,
    required double remainingAmount,
    required int dueDay,
    required int colorValue,
    required int iconCodePoint,
    double? totalAmount,
    double? installmentAmount,
    DateTime? startDate,
    String? accountId,
    bool reminderEnabled = false,
  }) async {
    final debt = await _ref.read(debtRepositoryProvider).create(
          name: name,
          type: type,
          remainingAmount: remainingAmount,
          dueDay: dueDay,
          colorValue: colorValue,
          iconCodePoint: iconCodePoint,
          totalAmount: totalAmount,
          installmentAmount: installmentAmount,
          startDate: startDate,
          accountId: accountId,
          reminderEnabled: reminderEnabled,
        );
    _refresh();
    return debt;
  }

  Future<void> saveDebt(Debt debt) async {
    await _ref.read(debtRepositoryProvider).save(debt);
    _refresh();
  }

  Future<void> deleteDebt(String id) async {
    await _ref.read(transactionRepositoryProvider).unlinkDebt(id);
    await _ref.read(debtRepositoryProvider).delete(id);
    _refresh();
  }

  /// Books a payment against [debt] as a real expense transaction (so it
  /// flows through reports/insights/health score) and reduces the debt's
  /// remaining balance by the same amount.
  Future<void> payDebt(
    Debt debt, {
    required double amount,
    required String accountId,
    required DateTime date,
    String? note,
  }) async {
    final categories = await _ref.read(categoryRepositoryProvider).getAll();
    final expenseCategories =
        categories.where((c) => c.kind == CategoryKind.expense);
    if (expenseCategories.isEmpty) {
      throw StateError(
          'Belum ada kategori pengeluaran. Buat kategori dulu di Pengaturan.');
    }
    final billCategory = expenseCategories.firstWhere(
      (c) => c.name == 'Tagihan',
      orElse: () => expenseCategories.first,
    );

    await addTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        title: 'Bayar ${debt.name}',
        amount: amount,
        accountId: accountId,
        categoryId: billCategory.id,
        transactionDateTime: date,
        note: note,
        debtId: debt.id,
      ),
    );
    final remaining = (debt.remainingAmount - amount).clamp(0, double.infinity);
    await saveDebt(debt.copyWith(
      remainingAmount: remaining.toDouble(),
      isSettled: remaining <= 0,
    ));
  }

  Future<RecurringRule> createRecurringRule({
    required String title,
    required TransactionType type,
    required double amount,
    required String accountId,
    required RecurringInterval intervalUnit,
    required int intervalCount,
    required DateTime nextDueDate,
    String? categoryId,
  }) async {
    final rule = await _ref.read(recurringRuleRepositoryProvider).create(
          title: title,
          type: type,
          amount: amount,
          accountId: accountId,
          intervalUnit: intervalUnit,
          intervalCount: intervalCount,
          nextDueDate: nextDueDate,
          categoryId: categoryId,
        );
    _refresh();
    return rule;
  }

  Future<void> saveRecurringRule(RecurringRule rule) async {
    await _ref.read(recurringRuleRepositoryProvider).save(rule);
    _refresh();
  }

  Future<void> deleteRecurringRule(String id) async {
    await _ref.read(recurringRuleRepositoryProvider).delete(id);
    await _ref.read(notificationServiceProvider).cancelReminderFor(
          'recurring',
          id,
        );
    _refresh();
  }

  /// Books the due occurrence as a real transaction and advances the rule
  /// to its next occurrence. Nothing is ever booked without this explicit
  /// call — a due rule just sits in the reminder list until the user acts.
  Future<void> confirmRecurring(RecurringRule rule, {DateTime? date}) async {
    final when = date ?? DateTime.now();
    await addTransaction(
      TransactionDraft(
        type: rule.type,
        title: rule.title,
        amount: rule.amount,
        accountId: rule.accountId,
        categoryId: rule.categoryId,
        transactionDateTime: when,
        note: 'Transaksi berulang',
      ),
    );
    await saveRecurringRule(rule.copyWith(
      nextDueDate: rule.advancedDueDate(),
      lastGeneratedDate: when,
    ));
  }

  /// Moves the rule to its next occurrence without booking a transaction.
  Future<void> skipRecurring(RecurringRule rule) async {
    await saveRecurringRule(
        rule.copyWith(nextDueDate: rule.advancedDueDate()));
  }

  Future<AllowanceLimit> createAllowanceLimit({
    required String accountId,
    required double limitAmount,
    required int year,
    required int month,
  }) async {
    final limit = await _ref.read(allowanceLimitRepositoryProvider).create(
          accountId: accountId,
          limitAmount: limitAmount,
          year: year,
          month: month,
        );
    _refresh();
    return limit;
  }

  Future<void> saveAllowanceLimit(AllowanceLimit limit) async {
    await _ref.read(allowanceLimitRepositoryProvider).save(limit);
    _refresh();
  }

  Future<void> deleteAllowanceLimit(String id) async {
    await _ref.read(allowanceLimitRepositoryProvider).delete(id);
    _refresh();
  }
}

final financeControllerProvider =
    Provider<FinanceController>((ref) => FinanceController(ref));
