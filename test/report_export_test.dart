import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:duitku/core/services/backup_service.dart';
import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/repositories/account_repository.dart';
import 'package:duitku/data/repositories/category_repository.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';
import 'package:duitku/data/models/transaction.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  test('builds a non-empty PDF document for a month with data', () async {
    final db = InMemoryDatabase();
    final accounts = AccountRepository(db);
    final categories = CategoryRepository(db);
    final transactions = TransactionRepository(db);

    final bca = await accounts.create(
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 1000000,
    );
    final gaji = await categories.create(
      name: 'Gaji',
      kind: CategoryKind.income,
      iconCodePoint: 1,
      colorValue: 1,
    );
    final makanan = await categories.create(
      name: 'Makanan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    await transactions.add(TransactionDraft(
      type: TransactionType.income,
      title: 'Gaji Agustus',
      amount: 5000000,
      accountId: bca.id,
      categoryId: gaji.id,
      transactionDateTime: DateTime(2026, 8, 5),
    ));
    await transactions.add(TransactionDraft(
      type: TransactionType.expense,
      title: 'Makan siang',
      amount: 50000,
      accountId: bca.id,
      categoryId: makanan.id,
      transactionDateTime: DateTime(2026, 8, 6),
    ));

    final doc = BackupService.buildMonthlyReportDocument(
      month: DateTime(2026, 8),
      accounts: await db.readAccounts(),
      categories: await db.readCategories(),
      transactions: await db.readTransactions(),
      currencyCode: 'IDR',
    );

    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    // A real PDF always starts with this magic header.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('still produces a valid PDF document for an empty month', () async {
    final doc = BackupService.buildMonthlyReportDocument(
      month: DateTime(2026, 8),
      accounts: const [],
      categories: const [],
      transactions: const [],
      currencyCode: 'IDR',
    );

    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
