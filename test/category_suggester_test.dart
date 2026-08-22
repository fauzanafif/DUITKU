import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/category_suggester.dart';
import 'package:duitku/data/models/transaction.dart';

void main() {
  TransactionRecord tx({
    required String title,
    required String categoryId,
    TransactionType type = TransactionType.expense,
  }) {
    final now = DateTime(2026, 8, 1);
    return TransactionRecord(
      id: title,
      type: type,
      title: title,
      amount: 10000,
      accountId: 'acc1',
      categoryId: categoryId,
      transactionDateTime: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('suggests the most frequently used category for a similar title', () {
    final history = [
      tx(title: 'Starbucks', categoryId: 'kopi'),
      tx(title: 'Starbucks Senayan', categoryId: 'kopi'),
      tx(title: 'Starbucks Grand Indo', categoryId: 'jajan'),
    ];

    final suggestion = CategorySuggester.suggest(
      'Starbucks',
      history,
      TransactionType.expense,
    );

    expect(suggestion, 'kopi');
  });

  test('returns null when there is no matching history', () {
    final history = [tx(title: 'Starbucks', categoryId: 'kopi')];

    final suggestion = CategorySuggester.suggest(
      'Beli laptop',
      history,
      TransactionType.expense,
    );

    expect(suggestion, isNull);
  });

  test('ignores transactions of a different type', () {
    final history = [
      tx(title: 'Gaji', categoryId: 'salary', type: TransactionType.income),
    ];

    final suggestion = CategorySuggester.suggest(
      'Gaji',
      history,
      TransactionType.expense,
    );

    expect(suggestion, isNull);
  });

  test('never suggests for very short, ambiguous titles', () {
    final history = [tx(title: 'ab', categoryId: 'kopi')];

    final suggestion = CategorySuggester.suggest(
      'ab',
      history,
      TransactionType.expense,
    );

    expect(suggestion, isNull);
  });
}
