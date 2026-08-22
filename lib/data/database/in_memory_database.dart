import 'dart:convert';

import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/app_settings.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';

/// Database used by tests. Values are round-tripped through JSON so it
/// behaves exactly like the persistent implementation.
class InMemoryDatabase implements DuitkuDatabase {
  final Map<String, String> _accounts = {};
  final Map<String, String> _categories = {};
  final Map<String, String> _transactions = {};
  final Map<String, String> _budgets = {};
  final Map<String, String> _goals = {};
  final Map<String, String> _debts = {};
  final Map<String, String> _recurringRules = {};
  String? _settings;

  @override
  Future<void> init() async {}

  List<T> _decodeAll<T>(
    Map<String, String> source,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return source.values
        .map((raw) => fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Account>> readAccounts() async =>
      _decodeAll(_accounts, Account.fromJson);

  @override
  Future<void> writeAccount(Account account) async =>
      _accounts[account.id] = jsonEncode(account.toJson());

  @override
  Future<void> deleteAccount(String id) async => _accounts.remove(id);

  @override
  Future<List<Category>> readCategories() async =>
      _decodeAll(_categories, Category.fromJson);

  @override
  Future<void> writeCategory(Category category) async =>
      _categories[category.id] = jsonEncode(category.toJson());

  @override
  Future<void> deleteCategory(String id) async => _categories.remove(id);

  @override
  Future<List<TransactionRecord>> readTransactions() async =>
      _decodeAll(_transactions, TransactionRecord.fromJson);

  @override
  Future<void> writeTransaction(TransactionRecord transaction) async =>
      _transactions[transaction.id] = jsonEncode(transaction.toJson());

  @override
  Future<void> deleteTransaction(String id) async => _transactions.remove(id);

  @override
  Future<List<Budget>> readBudgets() async =>
      _decodeAll(_budgets, Budget.fromJson);

  @override
  Future<void> writeBudget(Budget budget) async =>
      _budgets[budget.id] = jsonEncode(budget.toJson());

  @override
  Future<void> deleteBudget(String id) async => _budgets.remove(id);

  @override
  Future<List<SavingGoal>> readSavingGoals() async =>
      _decodeAll(_goals, SavingGoal.fromJson);

  @override
  Future<void> writeSavingGoal(SavingGoal goal) async =>
      _goals[goal.id] = jsonEncode(goal.toJson());

  @override
  Future<void> deleteSavingGoal(String id) async => _goals.remove(id);

  @override
  Future<List<Debt>> readDebts() async => _decodeAll(_debts, Debt.fromJson);

  @override
  Future<void> writeDebt(Debt debt) async =>
      _debts[debt.id] = jsonEncode(debt.toJson());

  @override
  Future<void> deleteDebt(String id) async => _debts.remove(id);

  @override
  Future<List<RecurringRule>> readRecurringRules() async =>
      _decodeAll(_recurringRules, RecurringRule.fromJson);

  @override
  Future<void> writeRecurringRule(RecurringRule rule) async =>
      _recurringRules[rule.id] = jsonEncode(rule.toJson());

  @override
  Future<void> deleteRecurringRule(String id) async =>
      _recurringRules.remove(id);

  @override
  Future<AppSettings> readSettings() async {
    final raw = _settings;
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> writeSettings(AppSettings settings) async =>
      _settings = jsonEncode(settings.toJson());

  @override
  Future<void> clearFinancialData() async {
    _accounts.clear();
    _categories.clear();
    _transactions.clear();
    _budgets.clear();
    _goals.clear();
    _debts.clear();
    _recurringRules.clear();
  }
}
