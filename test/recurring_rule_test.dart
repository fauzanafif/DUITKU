import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/transaction.dart';

void main() {
  RecurringRule ruleWith({
    required RecurringInterval unit,
    required int count,
    required DateTime nextDueDate,
  }) {
    final now = DateTime(2026, 1, 1);
    return RecurringRule(
      id: 'r1',
      title: 'Netflix',
      type: TransactionType.expense,
      amount: 54000,
      accountId: 'acc1',
      intervalUnit: unit,
      intervalCount: count,
      nextDueDate: nextDueDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('advances by days for a daily interval', () {
    final rule = ruleWith(
      unit: RecurringInterval.daily,
      count: 3,
      nextDueDate: DateTime(2026, 8, 10),
    );
    expect(rule.advancedDueDate(), DateTime(2026, 8, 13));
  });

  test('advances by weeks for a weekly interval', () {
    final rule = ruleWith(
      unit: RecurringInterval.weekly,
      count: 2,
      nextDueDate: DateTime(2026, 8, 10),
    );
    expect(rule.advancedDueDate(), DateTime(2026, 8, 24));
  });

  test('advances by months for a monthly interval, rolling the year over',
      () {
    final rule = ruleWith(
      unit: RecurringInterval.monthly,
      count: 1,
      nextDueDate: DateTime(2026, 12, 15),
    );
    expect(rule.advancedDueDate(), DateTime(2027, 1, 15));
  });

  test('advances by years for a yearly interval', () {
    final rule = ruleWith(
      unit: RecurringInterval.yearly,
      count: 1,
      nextDueDate: DateTime(2026, 8, 10),
    );
    expect(rule.advancedDueDate(), DateTime(2027, 8, 10));
  });

  test('isDue is true once the due date has passed', () {
    final overdue = ruleWith(
      unit: RecurringInterval.monthly,
      count: 1,
      nextDueDate: DateTime(2000, 1, 1),
    );
    expect(overdue.isDue, isTrue);
  });

  test('isDue is false for a future due date', () {
    final future = ruleWith(
      unit: RecurringInterval.monthly,
      count: 1,
      nextDueDate: DateTime(2100, 1, 1),
    );
    expect(future.isDue, isFalse);
  });

  test('an inactive rule is never due, even if overdue', () {
    final overdue = ruleWith(
      unit: RecurringInterval.monthly,
      count: 1,
      nextDueDate: DateTime(2000, 1, 1),
    ).copyWith(isActive: false);
    expect(overdue.isDue, isFalse);
  });
}
