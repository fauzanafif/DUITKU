import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/app_settings.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';

/// Offline-first storage backed by Hive.
///
/// Entities are stored as JSON strings which keeps the schema forward
/// compatible with the backup format and avoids generated type adapters.
class HiveDatabase implements DuitkuDatabase {
  static const _accountsBox = 'duitku_accounts';
  static const _categoriesBox = 'duitku_categories';
  static const _transactionsBox = 'duitku_transactions';
  static const _budgetsBox = 'duitku_budgets';
  static const _goalsBox = 'duitku_saving_goals';
  static const _debtsBox = 'duitku_debts';
  static const _recurringRulesBox = 'duitku_recurring_rules';
  static const _settingsBox = 'duitku_settings';
  static const _settingsKey = 'settings';

  late final Box<String> _accounts;
  late final Box<String> _categories;
  late final Box<String> _transactions;
  late final Box<String> _budgets;
  late final Box<String> _goals;
  late final Box<String> _debts;
  late final Box<String> _recurringRules;
  late final Box<String> _settings;

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter('duitku');
    _accounts = await Hive.openBox<String>(_accountsBox);
    _categories = await Hive.openBox<String>(_categoriesBox);
    _transactions = await Hive.openBox<String>(_transactionsBox);
    _budgets = await Hive.openBox<String>(_budgetsBox);
    _goals = await Hive.openBox<String>(_goalsBox);
    _debts = await Hive.openBox<String>(_debtsBox);
    _recurringRules = await Hive.openBox<String>(_recurringRulesBox);
    _settings = await Hive.openBox<String>(_settingsBox);
    _initialized = true;
  }

  List<T> _decodeAll<T>(
    Box<String> box,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final result = <T>[];
    for (final raw in box.values) {
      try {
        result.add(fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } on Object {
        // Skip unreadable rows rather than breaking the whole app.
        continue;
      }
    }
    return result;
  }

  @override
  Future<List<Account>> readAccounts() async =>
      _decodeAll(_accounts, Account.fromJson);

  @override
  Future<void> writeAccount(Account account) =>
      _accounts.put(account.id, jsonEncode(account.toJson()));

  @override
  Future<void> deleteAccount(String id) => _accounts.delete(id);

  @override
  Future<List<Category>> readCategories() async =>
      _decodeAll(_categories, Category.fromJson);

  @override
  Future<void> writeCategory(Category category) =>
      _categories.put(category.id, jsonEncode(category.toJson()));

  @override
  Future<void> deleteCategory(String id) => _categories.delete(id);

  @override
  Future<List<TransactionRecord>> readTransactions() async =>
      _decodeAll(_transactions, TransactionRecord.fromJson);

  @override
  Future<void> writeTransaction(TransactionRecord transaction) =>
      _transactions.put(transaction.id, jsonEncode(transaction.toJson()));

  @override
  Future<void> deleteTransaction(String id) => _transactions.delete(id);

  @override
  Future<List<Budget>> readBudgets() async =>
      _decodeAll(_budgets, Budget.fromJson);

  @override
  Future<void> writeBudget(Budget budget) =>
      _budgets.put(budget.id, jsonEncode(budget.toJson()));

  @override
  Future<void> deleteBudget(String id) => _budgets.delete(id);

  @override
  Future<List<SavingGoal>> readSavingGoals() async =>
      _decodeAll(_goals, SavingGoal.fromJson);

  @override
  Future<void> writeSavingGoal(SavingGoal goal) =>
      _goals.put(goal.id, jsonEncode(goal.toJson()));

  @override
  Future<void> deleteSavingGoal(String id) => _goals.delete(id);

  @override
  Future<List<Debt>> readDebts() async =>
      _decodeAll(_debts, Debt.fromJson);

  @override
  Future<void> writeDebt(Debt debt) =>
      _debts.put(debt.id, jsonEncode(debt.toJson()));

  @override
  Future<void> deleteDebt(String id) => _debts.delete(id);

  @override
  Future<List<RecurringRule>> readRecurringRules() async =>
      _decodeAll(_recurringRules, RecurringRule.fromJson);

  @override
  Future<void> writeRecurringRule(RecurringRule rule) =>
      _recurringRules.put(rule.id, jsonEncode(rule.toJson()));

  @override
  Future<void> deleteRecurringRule(String id) => _recurringRules.delete(id);

  @override
  Future<AppSettings> readSettings() async {
    final raw = _settings.get(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const AppSettings();
    }
  }

  @override
  Future<void> writeSettings(AppSettings settings) =>
      _settings.put(_settingsKey, jsonEncode(settings.toJson()));

  @override
  Future<void> clearFinancialData() async {
    await _accounts.clear();
    await _categories.clear();
    await _transactions.clear();
    await _budgets.clear();
    await _goals.clear();
    await _debts.clear();
    await _recurringRules.clear();
  }
}
