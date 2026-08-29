import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/features/activity_log/log_filter.dart';

void main() {
  late ProviderContainer container;
  late InMemoryDatabase db;

  setUp(() {
    db = InMemoryDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() => container.dispose());

  FinanceController controller() =>
      container.read(financeControllerProvider);

  Future<List<ActivityLogEntry>> logs() =>
      container.read(activityLogRepositoryProvider).getAll();

  Future<Account> seedAccount({double balance = 1000000}) => controller()
      .createAccount(name: 'BCA', type: AccountType.bank, initialBalance: balance);

  Future<Category> seedCategory({String name = 'Makanan'}) => controller()
      .createCategory(
          name: name,
          kind: CategoryKind.expense,
          iconCodePoint: 1,
          colorValue: 1);

  group('account logging', () {
    test('create logs one rekening entry', () async {
      final account = await seedAccount();
      final entries = await logs();
      expect(entries, hasLength(1));
      expect(entries.single.module, LogModule.rekening);
      expect(entries.single.action, LogAction.create);
      expect(entries.single.entityName, account.name);
    });

    test('update logs a diff detail', () async {
      final account = await seedAccount(balance: 500000);
      await controller()
          .saveAccount(account.copyWith(name: 'BCA Utama', initialBalance: 750000));
      final update = (await logs()).first;
      expect(update.action, LogAction.update);
      expect(update.module, LogModule.rekening);
      expect(update.entityName, 'BCA Utama');
      expect(update.detail, contains('→'));
    });

    test('delete logs and keeps earlier entries', () async {
      final account = await seedAccount();
      await controller().deleteAccount(account.id);
      final entries = await logs();
      expect(entries, hasLength(2));
      expect(entries.first.action, LogAction.delete);
      expect(entries.any((e) => e.action == LogAction.create), isTrue);
    });

    test('failed delete of a referenced account writes no log', () async {
      final account = await seedAccount();
      final category = await seedCategory();
      await controller().addTransaction(TransactionDraft(
        type: TransactionType.expense,
        title: 'Kopi',
        amount: 20000,
        accountId: account.id,
        categoryId: category.id,
        transactionDateTime: DateTime(2026, 8, 1),
      ));
      final before = (await logs()).length;
      await expectLater(
          () => controller().deleteAccount(account.id), throwsStateError);
      expect((await logs()).length, before);
      expect((await logs()).any((e) => e.action == LogAction.delete), isFalse);
    });
  });

  group('category logging', () {
    test('create / update / delete each log once', () async {
      final category = await seedCategory(name: 'Jajan');
      await controller().saveCategory(category.copyWith(name: 'Jajan Kantor'));
      await controller().deleteCategory(category.id);
      final entries = await logs();
      expect(entries, hasLength(3));
      expect(entries.map((e) => e.action),
          containsAll(LogAction.values));
      expect(entries.every((e) => e.module == LogModule.kategori), isTrue);
      final update = entries.firstWhere((e) => e.action == LogAction.update);
      expect(update.detail, contains('Jajan Kantor'));
    });
  });

  group('transaction logging', () {
    test('logged under the category name with amount diff on update',
        () async {
      final account = await seedAccount();
      final category = await seedCategory(name: 'Makanan');
      final record = await controller().addTransaction(TransactionDraft(
        type: TransactionType.expense,
        title: 'Nasi Padang',
        amount: 50000,
        accountId: account.id,
        categoryId: category.id,
        transactionDateTime: DateTime(2026, 8, 2),
      ));
      await controller().updateTransaction(
        record.id,
        TransactionDraft(
          type: TransactionType.expense,
          title: 'Nasi Padang',
          amount: 75000,
          accountId: account.id,
          categoryId: category.id,
          transactionDateTime: DateTime(2026, 8, 2),
        ),
      );
      await controller().deleteTransaction(record.id);

      final entries = await logs();
      final txEntries =
          entries.where((e) => e.module == LogModule.transaksi).toList();
      expect(txEntries, hasLength(3));
      expect(txEntries.every((e) => e.entityName == 'Makanan'), isTrue);
      final update =
          txEntries.firstWhere((e) => e.action == LogAction.update);
      expect(update.detail, contains('→'));
    });

    test('deleting a transaction keeps its log entry', () async {
      final account = await seedAccount();
      final category = await seedCategory();
      final record = await controller().addTransaction(TransactionDraft(
        type: TransactionType.expense,
        title: 'Kopi',
        amount: 20000,
        accountId: account.id,
        categoryId: category.id,
        transactionDateTime: DateTime(2026, 8, 3),
      ));
      await controller().deleteTransaction(record.id);
      expect(await db.readTransactions(), isEmpty);
      expect((await logs()).where((e) => e.module == LogModule.transaksi),
          hasLength(2));
    });
  });

  group('budget logging', () {
    test('create / update / delete log under the category name', () async {
      final category = await seedCategory(name: 'Transportasi');
      await controller().createBudget(
          categoryId: category.id, amount: 300000, year: 2026, month: 8);
      final budget = (await db.readBudgets()).single;
      await controller().saveBudget(budget.copyWith(amount: 400000));
      await controller().deleteBudget(budget.id);

      final entries =
          (await logs()).where((e) => e.module == LogModule.budget).toList();
      expect(entries, hasLength(3));
      expect(entries.every((e) => e.entityName == 'Transportasi'), isTrue);
      final update = entries.firstWhere((e) => e.action == LogAction.update);
      expect(update.detail, contains('→'));
    });
  });

  test('clearFinancialData never removes the activity log', () async {
    final account = await seedAccount();
    await controller().deleteAccount(account.id);
    final before = (await logs()).length;
    expect(before, greaterThan(0));

    await db.clearFinancialData();

    expect((await logs()).length, before);
    expect(await db.readAccounts(), isEmpty);
  });

  group('LogFilter', () {
    final base = <ActivityLogEntry>[
      ActivityLogEntry(
        id: '1',
        timestamp: DateTime(2026, 8, 1, 9),
        module: LogModule.transaksi,
        action: LogAction.create,
        entityName: 'Makanan',
        detail: 'Rp 50.000',
      ),
      ActivityLogEntry(
        id: '2',
        timestamp: DateTime(2026, 8, 10, 12),
        module: LogModule.budget,
        action: LogAction.update,
        entityName: 'Transportasi',
        detail: 'Rp 300.000 → Rp 400.000',
      ),
      ActivityLogEntry(
        id: '3',
        timestamp: DateTime(2026, 8, 20, 15),
        module: LogModule.rekening,
        action: LogAction.delete,
        entityName: 'BCA',
      ),
    ];

    test('filters by module, action, keyword and date range', () {
      expect(
          const LogFilter(module: LogModule.budget).apply(base).map((e) => e.id),
          ['2']);
      expect(
          const LogFilter(action: LogAction.delete)
              .apply(base)
              .map((e) => e.id),
          ['3']);
      expect(const LogFilter(query: 'transport').apply(base).map((e) => e.id),
          ['2']);
      expect(
          LogFilter(dateFrom: DateTime(2026, 8, 5), dateTo: DateTime(2026, 8, 15))
              .apply(base)
              .map((e) => e.id),
          ['2']);
    });

    test('empty filter is inactive and returns everything newest-first', () {
      const filter = LogFilter();
      expect(filter.isActive, isFalse);
      expect(filter.apply(base).map((e) => e.id), ['3', '2', '1']);
    });
  });
}
