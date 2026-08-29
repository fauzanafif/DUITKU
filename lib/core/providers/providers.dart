import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/services/backup_service.dart';
import 'package:duitku/core/services/biometric_service.dart';
import 'package:duitku/core/services/notification_service.dart';
import 'package:duitku/core/services/pin_service.dart';
import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:duitku/data/models/app_settings.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/activity_log_repository.dart';
import 'package:duitku/data/repositories/allowance_limit_repository.dart';
import 'package:duitku/data/repositories/budget_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/debt_repository.dart';
import 'package:duitku/data/repositories/recurring_rule_repository.dart';
import 'package:duitku/data/repositories/saving_goal_repository.dart';
import 'package:duitku/data/repositories/settings_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

/// Overridden in `main()` (and in tests) with a concrete implementation.
final databaseProvider = Provider<DuitkuDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final accountRepositoryProvider = Provider<AccountRepository>(
    (ref) => AccountRepository(ref.watch(databaseProvider)));

final categoryRepositoryProvider = Provider<CategoryRepository>(
    (ref) => CategoryRepository(ref.watch(databaseProvider)));

final transactionRepositoryProvider = Provider<TransactionRepository>(
    (ref) => TransactionRepository(ref.watch(databaseProvider)));

final budgetRepositoryProvider = Provider<BudgetRepository>(
    (ref) => BudgetRepository(ref.watch(databaseProvider)));

final savingGoalRepositoryProvider = Provider<SavingGoalRepository>(
    (ref) => SavingGoalRepository(ref.watch(databaseProvider)));

final debtRepositoryProvider = Provider<DebtRepository>(
    (ref) => DebtRepository(ref.watch(databaseProvider)));

final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>(
    (ref) => RecurringRuleRepository(ref.watch(databaseProvider)));

final allowanceLimitRepositoryProvider = Provider<AllowanceLimitRepository>(
    (ref) => AllowanceLimitRepository(ref.watch(databaseProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(databaseProvider)));

final activityLogRepositoryProvider = Provider<ActivityLogRepository>(
    (ref) => ActivityLogRepository(ref.watch(databaseProvider)));

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));

final pinServiceProvider = Provider<PinService>((ref) => const PinService());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final accountsProvider = FutureProvider<List<Account>>(
    (ref) => ref.watch(accountRepositoryProvider).getAll());

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).getAll());

final transactionsProvider = FutureProvider<List<TransactionRecord>>(
    (ref) => ref.watch(transactionRepositoryProvider).getAll());

final budgetsProvider = FutureProvider<List<Budget>>(
    (ref) => ref.watch(budgetRepositoryProvider).getAll());

final savingGoalsProvider = FutureProvider<List<SavingGoal>>(
    (ref) => ref.watch(savingGoalRepositoryProvider).getAll());

final debtsProvider = FutureProvider<List<Debt>>(
    (ref) => ref.watch(debtRepositoryProvider).getAll());

final recurringRulesProvider = FutureProvider<List<RecurringRule>>(
    (ref) => ref.watch(recurringRuleRepositoryProvider).getAll());

final allowanceLimitsProvider = FutureProvider<List<AllowanceLimit>>(
    (ref) => ref.watch(allowanceLimitRepositoryProvider).getAll());

final activityLogsProvider = FutureProvider<List<ActivityLogEntry>>(
    (ref) => ref.watch(activityLogRepositoryProvider).getAll());

/// Active rules whose next occurrence is already due. Pure read — nothing
/// is ever booked or advanced just by looking at this list; the user must
/// explicitly confirm or skip each one.
final recurringDueProvider = Provider<List<RecurringRule>>((ref) {
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];
  return rules.where((rule) => rule.isDue).toList();
});

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() =>
      ref.watch(settingsRepositoryProvider).get();

  Future<void> save(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }

  Future<void> mutate(AppSettings Function(AppSettings current) transform) async {
    final current = state.valueOrNull ?? const AppSettings();
    await save(transform(current));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Convenience accessors for widgets that only need the resolved value.
extension SettingsRef on WidgetRef {
  AppSettings get settings =>
      watch(settingsProvider).valueOrNull ?? const AppSettings();
}

final List<ProviderOrFamily> financialProviders = [
  accountsProvider,
  transactionsProvider,
  categoriesProvider,
  budgetsProvider,
  savingGoalsProvider,
  debtsProvider,
  recurringRulesProvider,
  allowanceLimitsProvider,
  activityLogsProvider,
];

void invalidateFinancialData(Ref ref) {
  for (final provider in financialProviders) {
    ref.invalidate(provider);
  }
}

void invalidateFinancialDataFrom(WidgetRef ref) {
  for (final provider in financialProviders) {
    ref.invalidate(provider);
  }
}
