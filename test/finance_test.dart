import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/finance/transaction_validator.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/budget_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

void main() {
  late InMemoryDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late BudgetRepository budgets;

  setUp(() {
    db = InMemoryDatabase();
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    transactions = TransactionRepository(db);
    budgets = BudgetRepository(db);
  });

  test('currency formatter respects the selected currency code', () {
    expect(
      Formatters.currency(1234567, currencyCode: 'USD'),
      r'$1,234,567',
    );
    expect(
      Formatters.currency(1234567, currencyCode: 'EUR'),
      '€1,234,567',
    );
  });

  Future<double> balanceOf(Account account) async =>
      FinanceCalculator.accountBalance(account, await db.readTransactions());

  Future<double> totalBalance() async => FinanceCalculator.totalBalance(
        await db.readAccounts(),
        await db.readTransactions(),
      );

  Future<Account> createAccount(
    String name,
    AccountType type,
    double initialBalance,
  ) =>
      accounts.create(name: name, type: type, initialBalance: initialBalance);

  Future<Category> createIncomeCategory(String name) => categories.create(
        name: name,
        kind: CategoryKind.income,
        iconCodePoint: 1,
        colorValue: 1,
      );

  Future<Category> createExpenseCategory(String name) => categories.create(
        name: name,
        kind: CategoryKind.expense,
        iconCodePoint: 1,
        colorValue: 1,
      );

  const allTime = DateRange.unbounded();

  test('1. income increases the destination account balance', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final gaji = await createIncomeCategory('Gaji');

    await transactions.add(TransactionDraft(
      type: TransactionType.income,
      title: 'Gaji',
      amount: 1000000,
      accountId: bca.id,
      categoryId: gaji.id,
      transactionDateTime: DateTime(2026, 8, 14, 9),
    ));

    expect(await balanceOf(bca), 6000000);
    expect(
      FinanceCalculator.totalIncome(await db.readTransactions(), allTime),
      1000000,
    );
  });

  test('2. expense decreases the account and counts as expense', () async {
    final cash = await createAccount('Cash', AccountType.cash, 500000);
    final makanan = await createExpenseCategory('Makanan');

    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan',
      amount: 50000,
      accountId: cash.id,
      categoryId: makanan.id,
      transactionDateTime: DateTime(2026, 8, 14, 12, 30),
    ));

    expect(await balanceOf(cash), 450000);
    expect(
      FinanceCalculator.totalExpense(await db.readTransactions(), allTime),
      50000,
    );
  });

  test('3. tarik cash is a transfer: total balance and expense unchanged',
      () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final cash = await createAccount('Cash', AccountType.cash, 0);

    await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Tarik Cash',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: cash.id,
      transactionDateTime: DateTime(2026, 8, 14, 10, 30),
    ));

    final stored = await db.readTransactions();
    expect(await balanceOf(bca), 4500000);
    expect(await balanceOf(cash), 500000);
    expect(await totalBalance(), 5000000);
    expect(FinanceCalculator.totalExpense(stored, allTime), 0);
    expect(FinanceCalculator.totalIncome(stored, allTime), 0);
  });

  test('4. spending cash after a withdrawal is a real expense', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final cash = await createAccount('Cash', AccountType.cash, 0);
    final makanan = await createExpenseCategory('Makanan');

    await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Tarik Cash',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: cash.id,
      transactionDateTime: DateTime(2026, 8, 14, 10),
    ));
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan',
      amount: 50000,
      accountId: cash.id,
      categoryId: makanan.id,
      transactionDateTime: DateTime(2026, 8, 14, 12),
    ));

    final stored = await db.readTransactions();
    expect(await balanceOf(cash), 450000);
    expect(FinanceCalculator.totalExpense(stored, allTime), 50000);
    expect(await totalBalance(), 4950000);

    final budget = await budgets.create(
      categoryId: makanan.id,
      amount: 1000000,
      year: 2026,
      month: 8,
    );
    final status = FinanceCalculator.budgetStatus(budget, stored);
    expect(status.used, 50000, reason: 'transfers must not touch the budget');
    expect(status.remaining, 950000);
  });

  test('5. bank to bank transfer keeps the total balance', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final mandiri = await createAccount('Mandiri', AccountType.bank, 1000000);

    await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Pindah dana',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: mandiri.id,
      transactionDateTime: DateTime(2026, 8, 14, 11),
    ));

    expect(await balanceOf(bca), 4500000);
    expect(await balanceOf(mandiri), 1500000);
    expect(await totalBalance(), 6000000);
  });

  test('6. reports use transactionDateTime, never createdAt', () async {
    final bca = await createAccount('BCA', AccountType.bank, 0);
    final gaji = await createIncomeCategory('Gaji');

    final record = await transactions.add(TransactionDraft(
      type: TransactionType.income,
      title: 'Gaji Juli',
      amount: 5000000,
      accountId: bca.id,
      categoryId: gaji.id,
      transactionDateTime: DateTime(2026, 7, 31, 9),
    ));

    expect(record.transactionDateTime.month, 7);
    expect(record.createdAt.isAfter(record.transactionDateTime), isTrue);

    final stored = await db.readTransactions();
    expect(
      FinanceCalculator.totalIncome(stored, DateRange.month(2026, 7)),
      5000000,
    );
    expect(
      FinanceCalculator.totalIncome(stored, DateRange.month(2026, 8)),
      0,
    );
  });

  test('7. editing a transfer applies only the new amount', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final cash = await createAccount('Cash', AccountType.cash, 0);

    final record = await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Tarik Cash',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: cash.id,
      transactionDateTime: DateTime(2026, 8, 14, 10),
    ));

    await transactions.update(
      record.id,
      TransactionDraft(
        type: TransactionType.transfer,
        title: 'Tarik Cash',
        amount: 750000,
        accountId: bca.id,
        destinationAccountId: cash.id,
        transactionDateTime: record.transactionDateTime,
      ),
    );

    expect((await db.readTransactions()).length, 1);
    expect(await balanceOf(bca), 4250000);
    expect(await balanceOf(cash), 750000);
    expect(await totalBalance(), 5000000);
  });

  test('8. deleting a transfer restores both balances', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final cash = await createAccount('Cash', AccountType.cash, 0);

    final record = await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Tarik Cash',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: cash.id,
      transactionDateTime: DateTime(2026, 8, 14, 10),
    ));

    await transactions.delete(record.id);

    expect(await db.readTransactions(), isEmpty);
    expect(await balanceOf(bca), 5000000);
    expect(await balanceOf(cash), 0);
    expect(await totalBalance(), 5000000);
  });

  test('deleting an expense gives the money back', () async {
    final cash = await createAccount('Cash', AccountType.cash, 500000);
    final makanan = await createExpenseCategory('Makanan');
    final record = await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan',
      amount: 50000,
      accountId: cash.id,
      categoryId: makanan.id,
      transactionDateTime: DateTime(2026, 8, 14, 12),
    ));

    await transactions.delete(record.id);
    expect(await balanceOf(cash), 500000);
  });

  test('validation rejects invalid transfers and overspending', () async {
    final bca = await createAccount('BCA', AccountType.bank, 100000);
    final cash = await createAccount('Cash', AccountType.cash, 0);
    final lainnya = await createExpenseCategory('Lainnya');

    Future<void> attempt(TransactionDraft draft) =>
        transactions.add(draft);

    await expectLater(
      attempt(TransactionDraft(
        type: TransactionType.transfer,
        title: 'Ke diri sendiri',
        amount: 10000,
        accountId: bca.id,
        destinationAccountId: bca.id,
        transactionDateTime: DateTime(2026, 8, 14),
      )),
      throwsA(isA<ValidationFailure>()),
    );

    await expectLater(
      attempt(TransactionDraft(
        type: TransactionType.expense,
        title: 'Nol',
        amount: 0,
        accountId: bca.id,
        categoryId: lainnya.id,
        transactionDateTime: DateTime(2026, 8, 14),
      )),
      throwsA(isA<ValidationFailure>()),
    );

    await expectLater(
      attempt(TransactionDraft(
        type: TransactionType.transfer,
        title: 'Kebanyakan',
        amount: 999999999,
        accountId: bca.id,
        destinationAccountId: cash.id,
        transactionDateTime: DateTime(2026, 8, 14),
      )),
      throwsA(isA<ValidationFailure>()),
    );

    expect(await db.readTransactions(), isEmpty);
  });

  test('cash report separates transfers from real spending', () async {
    final bca = await createAccount('BCA', AccountType.bank, 5000000);
    final cash = await createAccount('Cash', AccountType.cash, 0);
    final belanja = await createExpenseCategory('Belanja');

    await transactions.add(TransactionDraft(
      type: TransactionType.transfer,
      title: 'Tarik Cash',
      amount: 500000,
      accountId: bca.id,
      destinationAccountId: cash.id,
      transactionDateTime: DateTime(2026, 8, 2, 9),
    ));
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Belanja',
      amount: 200000,
      accountId: cash.id,
      categoryId: belanja.id,
      transactionDateTime: DateTime(2026, 8, 3, 9),
    ));

    final stored = await db.readTransactions();
    final august = DateRange.month(2026, 8);

    expect(FinanceCalculator.inflow(stored, cash.id, august), 500000);
    expect(
      FinanceCalculator.inflow(stored, cash.id, august,
          includeTransfers: false),
      0,
      reason: 'a withdrawal is not income',
    );
    expect(FinanceCalculator.outflow(stored, cash.id, august), 200000);
    expect(await balanceOf(cash), 300000);
  });

  test('category deletion requires a replacement when it is in use', () async {
    final cash = await createAccount('Cash', AccountType.cash, 500000);
    final makanan = await createExpenseCategory('Makanan');
    final lainnya = await createExpenseCategory('Lainnya');

    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan',
      amount: 50000,
      accountId: cash.id,
      categoryId: makanan.id,
      transactionDateTime: DateTime(2026, 8, 14),
    ));

    await expectLater(
      categories.delete(makanan.id),
      throwsA(isA<StateError>()),
    );

    await categories.delete(makanan.id, reassignTo: lainnya.id);
    final stored = await db.readTransactions();
    expect(stored.single.categoryId, lainnya.id);
  });
}
