import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/transaction.dart';

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

  test('confirmRecurring books a transaction and advances the due date',
      () async {
    final controller = container.read(financeControllerProvider);
    final account = await controller.createAccount(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 1000000,
    );
    await controller.createCategory(
      name: 'Hiburan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final categories = await db.readCategories();
    final categoryId = categories.first.id;
    final rule = await controller.createRecurringRule(
      title: 'Netflix',
      type: TransactionType.expense,
      amount: 54000,
      accountId: account.id,
      categoryId: categoryId,
      intervalUnit: RecurringInterval.monthly,
      intervalCount: 1,
      nextDueDate: DateTime(2026, 8, 1),
    );

    await controller.confirmRecurring(rule, date: DateTime(2026, 8, 1));

    final transactions = await db.readTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.single.amount, 54000);
    expect(transactions.single.categoryId, categoryId);

    final storedRule = (await db.readRecurringRules()).single;
    expect(storedRule.nextDueDate, DateTime(2026, 9, 1));
    expect(storedRule.lastGeneratedDate, DateTime(2026, 8, 1));
  });

  test('skipRecurring advances the due date without booking a transaction',
      () async {
    final controller = container.read(financeControllerProvider);
    final account = await controller.createAccount(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 1000000,
    );
    final rule = await controller.createRecurringRule(
      title: 'Gym',
      type: TransactionType.expense,
      amount: 300000,
      accountId: account.id,
      intervalUnit: RecurringInterval.monthly,
      intervalCount: 1,
      nextDueDate: DateTime(2026, 8, 1),
    );

    await controller.skipRecurring(rule);

    expect(await db.readTransactions(), isEmpty);
    final storedRule = (await db.readRecurringRules()).single;
    expect(storedRule.nextDueDate, DateTime(2026, 9, 1));
  });
}
