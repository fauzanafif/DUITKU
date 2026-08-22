import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/insight_calculator.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';

void main() {
  late InMemoryDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late TransactionRepository transactions;

  setUp(() {
    db = InMemoryDatabase();
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    transactions = TransactionRepository(db);
  });

  test('month-over-month insight flags a category that grew', () async {
    final bca = await accounts.create(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 5000000,
    );
    final food = await categories.create(
      name: 'Makanan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );

    // Last month: Rp 100.000 spent on Makanan.
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan siang',
      amount: 100000,
      accountId: bca.id,
      categoryId: food.id,
      transactionDateTime: DateTime(2026, 7, 10),
    ));

    // This month: Rp 150.000 spent on Makanan (a 50% increase).
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan malam',
      amount: 150000,
      accountId: bca.id,
      categoryId: food.id,
      transactionDateTime: DateTime(2026, 8, 10),
    ));

    final insight = InsightCalculator.monthOverMonth(
      await db.readTransactions(),
      DateTime(2026, 8),
    );

    expect(insight.expense, 150000);
    expect(insight.previousExpense, 100000);
    expect(insight.expensePercentChange, closeTo(50, 0.01));
    expect(insight.topCategoryChanges, hasLength(1));
    expect(insight.topCategoryChanges.first.categoryId, food.id);
    expect(insight.topCategoryChanges.first.percentChange, closeTo(50, 0.01));
  });

  test('a brand-new category with no previous-month baseline is excluded',
      () async {
    final bca = await accounts.create(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 5000000,
    );
    final hobby = await categories.create(
      name: 'Hobi',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );

    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Alat lukis',
      amount: 200000,
      accountId: bca.id,
      categoryId: hobby.id,
      transactionDateTime: DateTime(2026, 8, 5),
    ));

    final insight = InsightCalculator.monthOverMonth(
      await db.readTransactions(),
      DateTime(2026, 8),
    );

    expect(insight.topCategoryChanges, isEmpty);
  });
}
