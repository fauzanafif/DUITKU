import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/debt_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

void main() {
  late InMemoryDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late DebtRepository debts;

  setUp(() {
    db = InMemoryDatabase();
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    transactions = TransactionRepository(db);
    debts = DebtRepository(db);
  });

  test('paying a debt books a linked expense and reduces the balance',
      () async {
    final bca = await accounts.create(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 5000000,
    );
    final tagihan = await categories.create(
      name: 'Tagihan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final debt = await debts.create(
      name: 'Kartu Kredit',
      type: DebtType.creditCard,
      remainingAmount: 1000000,
      dueDay: 15,
      colorValue: 1,
      iconCodePoint: 1,
    );

    // What FinanceController.payDebt does: book the payment, then shrink
    // the remaining balance by the same amount.
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Bayar ${debt.name}',
      amount: 300000,
      accountId: bca.id,
      categoryId: tagihan.id,
      transactionDateTime: DateTime(2026, 8, 10),
      debtId: debt.id,
    ));
    final updated = debt.copyWith(remainingAmount: 700000);
    await debts.save(updated);

    final storedDebts = await debts.getAll();
    expect(storedDebts.single.remainingAmount, 700000);

    final storedTransactions = await db.readTransactions();
    expect(storedTransactions.single.debtId, debt.id);
    expect(storedTransactions.single.amount, 300000);
  });

  test('deleting a debt unlinks its payment history instead of deleting it',
      () async {
    final bca = await accounts.create(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 5000000,
    );
    final tagihan = await categories.create(
      name: 'Tagihan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final debt = await debts.create(
      name: 'Paylater',
      type: DebtType.paylater,
      remainingAmount: 500000,
      dueDay: 5,
      colorValue: 1,
      iconCodePoint: 1,
    );
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Bayar ${debt.name}',
      amount: 200000,
      accountId: bca.id,
      categoryId: tagihan.id,
      transactionDateTime: DateTime(2026, 8, 5),
      debtId: debt.id,
    ));

    await transactions.unlinkDebt(debt.id);
    await debts.delete(debt.id);

    expect(await debts.getAll(), isEmpty);
    final remainingTransactions = await db.readTransactions();
    expect(remainingTransactions, hasLength(1));
    expect(remainingTransactions.single.debtId, isNull);
    expect(remainingTransactions.single.amount, 200000);
  });

  test('a debt fully paid off reaches zero remaining amount', () async {
    final debt = await debts.create(
      name: 'Cicilan Motor',
      type: DebtType.installment,
      remainingAmount: 100000,
      dueDay: 20,
      colorValue: 1,
      iconCodePoint: 1,
      totalAmount: 5000000,
    );

    final settled = debt.copyWith(remainingAmount: 0, isSettled: true);
    await debts.save(settled);

    final stored = (await debts.getAll()).single;
    expect(stored.remainingAmount, 0);
    expect(stored.isSettled, isTrue);
    expect(stored.progress, 1.0);
  });
}
