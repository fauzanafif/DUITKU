import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/date_range.dart';

void main() {
  group('financialMonth', () {
    test('payday=1 matches the plain calendar month exactly', () {
      final calendar = DateRange.month(2026, 8);
      final financial = DateRange.financialMonth(2026, 8, 1);
      expect(financial.start, calendar.start);
      expect(financial.end, calendar.end);
    });

    test('payday=25 produces a 25th-to-24th cycle', () {
      final range = DateRange.financialMonth(2026, 8, 25);
      expect(range.start, DateTime(2026, 8, 25));
      expect(range.end, DateTime(2026, 9, 25));
    });

    test('payday=31 clamps to the last day of a shorter month', () {
      final range = DateRange.financialMonth(2026, 2, 31);
      expect(range.start, DateTime(2026, 2, 28));
      expect(range.end, DateTime(2026, 3, 31));
    });
  });

  group('financialMonthLabel', () {
    test('a moment on/after this month\'s payday keeps this month\'s label',
        () {
      final label = DateRange.financialMonthLabel(DateTime(2026, 8, 25), 25);
      expect(label.year, 2026);
      expect(label.month, 8);
    });

    test('a moment before this month\'s payday belongs to last month\'s label',
        () {
      final label = DateRange.financialMonthLabel(DateTime(2026, 8, 10), 25);
      expect(label.year, 2026);
      expect(label.month, 7);
    });

    test('label rolls the year over in January', () {
      final label = DateRange.financialMonthLabel(DateTime(2026, 1, 5), 25);
      expect(label.year, 2025);
      expect(label.month, 12);
    });
  });

  group('fromPreset with payday', () {
    test('thisMonth resolves to the cycle currently in progress', () {
      final range = DateRange.fromPreset(
        PeriodPreset.thisMonth,
        now: DateTime(2026, 8, 10),
        payday: 25,
      );
      expect(range.start, DateTime(2026, 7, 25));
      expect(range.end, DateTime(2026, 8, 25));
    });

    test('lastMonth resolves to the cycle before the one in progress', () {
      final range = DateRange.fromPreset(
        PeriodPreset.lastMonth,
        now: DateTime(2026, 8, 10),
        payday: 25,
      );
      expect(range.start, DateTime(2026, 6, 25));
      expect(range.end, DateTime(2026, 7, 25));
    });

    test('default payday=1 keeps the old calendar-month behavior', () {
      final range = DateRange.fromPreset(
        PeriodPreset.thisMonth,
        now: DateTime(2026, 8, 10),
      );
      expect(range.start, DateTime(2026, 8));
      expect(range.end, DateTime(2026, 9));
    });
  });
}
