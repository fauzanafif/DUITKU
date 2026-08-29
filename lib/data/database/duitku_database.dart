import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:duitku/data/models/app_settings.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';

/// Storage contract for every persisted entity.
///
/// The app ships a Hive implementation; tests use an in-memory one.
abstract class DuitkuDatabase {
  Future<void> init();

  Future<List<Account>> readAccounts();
  Future<void> writeAccount(Account account);
  Future<void> deleteAccount(String id);

  Future<List<Category>> readCategories();
  Future<void> writeCategory(Category category);
  Future<void> deleteCategory(String id);

  Future<List<TransactionRecord>> readTransactions();
  Future<void> writeTransaction(TransactionRecord transaction);
  Future<void> deleteTransaction(String id);

  Future<List<Budget>> readBudgets();
  Future<void> writeBudget(Budget budget);
  Future<void> deleteBudget(String id);

  Future<List<SavingGoal>> readSavingGoals();
  Future<void> writeSavingGoal(SavingGoal goal);
  Future<void> deleteSavingGoal(String id);

  Future<List<Debt>> readDebts();
  Future<void> writeDebt(Debt debt);
  Future<void> deleteDebt(String id);

  Future<List<RecurringRule>> readRecurringRules();
  Future<void> writeRecurringRule(RecurringRule rule);
  Future<void> deleteRecurringRule(String id);

  Future<List<AllowanceLimit>> readAllowanceLimits();
  Future<void> writeAllowanceLimit(AllowanceLimit limit);
  Future<void> deleteAllowanceLimit(String id);

  Future<AppSettings> readSettings();
  Future<void> writeSettings(AppSettings settings);

  /// Activity Log is an append-only audit trail. It is deliberately absent
  /// from [clearFinancialData] and from the backup JSON so the history is
  /// never lost, whatever happens to the financial data.
  Future<List<ActivityLogEntry>> readActivityLogs();
  Future<void> writeActivityLog(ActivityLogEntry entry);

  /// Wipes every collection except settings and the activity log.
  /// Used by the restore flow.
  Future<void> clearFinancialData();
}
