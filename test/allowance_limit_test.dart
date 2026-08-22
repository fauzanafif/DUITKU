import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/allowance_limit_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

void main() {
  late InMemoryDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late AllowanceLimitRepository limits;

  setUp(() {
    db = InMemoryDatabase();
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    transactions = TransactionRepository(db);
    limits = AllowanceLimitRepository(db);
  });

  test('create/save round-trips through the database', () async {
    final kid = await accounts.create(
      name: 'Uang Jajan Kaka',
      type: AccountType.allowance,
      initialBalance: 100000,
    );

    final limit = await limits.create(
      accountId: kid.id,
      limitAmount: 200000,
      year: 2026,
      month: 8,
    );

    final stored = (await limits.getAll()).single;
    expect(stored.id, limit.id);
    expect(stored.limitAmount, 200000);

    await limits.save(stored.copyWith(limitAmount: 250000));
    expect((await limits.getAll()).single.limitAmount, 250000);
  });

  test('spending against an allowance account respects the payday cycle',
      () async {
    final kid = await accounts.create(
      name: 'Uang Jajan Kaka',
      type: AccountType.allowance,
      initialBalance: 500000,
    );
    final jajan = await categories.create(
      name: 'Jajan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    await limits.create(
      accountId: kid.id,
      limitAmount: 100000,
      year: 2026,
      month: 8,
    );

    // Belongs to the July 25 - August 24 cycle (payday 25) since it's
    // before this month's payday.
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Jajan sebelum gajian',
      amount: 30000,
      accountId: kid.id,
      categoryId: jajan.id,
      transactionDateTime: DateTime(2026, 8, 10),
    ));
    // Belongs to the August 25 - September 24 cycle.
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Jajan setelah gajian',
      amount: 40000,
      accountId: kid.id,
      categoryId: jajan.id,
      transactionDateTime: DateTime(2026, 8, 26),
    ));

    const payday = 25;
    final augustCycleLabel =
        DateRange.financialMonthLabel(DateTime(2026, 8, 26), payday);
    final augustRange = DateRange.financialMonth(
        augustCycleLabel.year, augustCycleLabel.month, payday);

    final usedInAugustCycle = FinanceCalculator.outflow(
      await db.readTransactions(),
      kid.id,
      augustRange,
      includeTransfers: false,
    );

    // Only the Aug 26 transaction falls in the cycle that contains Aug 26.
    expect(usedInAugustCycle, 40000);
  });
}
