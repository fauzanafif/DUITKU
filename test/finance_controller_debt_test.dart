import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/debt.dart';

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

  test('payDebt auto-picks the Tagihan category when it exists', () async {
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
    await controller.createCategory(
      name: 'Tagihan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final debt = await controller.createDebt(
      name: 'Kartu Kredit',
      type: DebtType.creditCard,
      remainingAmount: 500000,
      dueDay: 10,
      colorValue: 1,
      iconCodePoint: 1,
    );

    await controller.payDebt(
      debt,
      amount: 200000,
      accountId: account.id,
      date: DateTime(2026, 8, 10),
    );

    final transactions = await db.readTransactions();
    final categories = await db.readCategories();
    final tagihan = categories.firstWhere((c) => c.name == 'Tagihan');
    expect(transactions.single.categoryId, tagihan.id);
    expect((await db.readDebts()).single.remainingAmount, 300000);
  });

  test(
      'payDebt falls back to the first expense category when there is no Tagihan',
      () async {
    final controller = container.read(financeControllerProvider);
    final account = await controller.createAccount(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 1000000,
    );
    await controller.createCategory(
      name: 'Belanja',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final debt = await controller.createDebt(
      name: 'Paylater',
      type: DebtType.paylater,
      remainingAmount: 200000,
      dueDay: 5,
      colorValue: 1,
      iconCodePoint: 1,
    );

    await controller.payDebt(
      debt,
      amount: 100000,
      accountId: account.id,
      date: DateTime(2026, 8, 5),
    );

    final transactions = await db.readTransactions();
    final categories = await db.readCategories();
    expect(transactions.single.categoryId, categories.single.id);
  });

  test('payDebt fails clearly when there is no expense category at all',
      () async {
    final controller = container.read(financeControllerProvider);
    final account = await controller.createAccount(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 1000000,
    );
    final debt = await controller.createDebt(
      name: 'Cicilan',
      type: DebtType.installment,
      remainingAmount: 200000,
      dueDay: 5,
      colorValue: 1,
      iconCodePoint: 1,
    );

    expect(
      () => controller.payDebt(
        debt,
        amount: 100000,
        accountId: account.id,
        date: DateTime(2026, 8, 5),
      ),
      throwsStateError,
    );
  });
}
