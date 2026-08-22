import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/data/models/transaction.dart';

/// Change of a single category's spending vs. the previous month.
class CategoryChange {
  const CategoryChange({
    required this.categoryId,
    required this.current,
    required this.previous,
  });

  final String? categoryId;
  final double current;
  final double previous;

  double get delta => current - previous;

  /// Null when there is no previous-period baseline to compare against.
  double? get percentChange =>
      previous == 0 ? null : (delta / previous) * 100;
}

class MonthOverMonthInsight {
  const MonthOverMonthInsight({
    required this.expense,
    required this.previousExpense,
    required this.topCategoryChanges,
  });

  final double expense;
  final double previousExpense;

  /// Categories with a previous-month baseline, sorted by the size of the
  /// change (biggest swing first).
  final List<CategoryChange> topCategoryChanges;

  double get expenseDelta => expense - previousExpense;

  /// Null when the previous month had no spending to compare against.
  double? get expensePercentChange =>
      previousExpense == 0 ? null : (expenseDelta / previousExpense) * 100;
}

/// Compares this month against last month using data that already exists
/// (no separate tracking needed — every insight is derived on the fly).
class InsightCalculator {
  const InsightCalculator._();

  static MonthOverMonthInsight monthOverMonth(
    Iterable<TransactionRecord> transactions,
    DateTime month, {
    int payday = 1,
  }) {
    final range = DateRange.financialMonth(month.year, month.month, payday);
    final previousRange =
        DateRange.financialMonth(month.year, month.month - 1, payday);

    final currentBreakdown =
        FinanceCalculator.breakdownByCategory(transactions, range);
    final previousTotals = {
      for (final entry
          in FinanceCalculator.breakdownByCategory(transactions, previousRange))
        entry.categoryId: entry.total,
    };

    final changes = currentBreakdown
        .map((entry) => CategoryChange(
              categoryId: entry.categoryId,
              current: entry.total,
              previous: previousTotals[entry.categoryId] ?? 0,
            ))
        .where((change) => change.percentChange != null)
        .toList()
      ..sort(
        (a, b) => b.percentChange!.abs().compareTo(a.percentChange!.abs()),
      );

    return MonthOverMonthInsight(
      expense: FinanceCalculator.totalExpense(transactions, range),
      previousExpense: FinanceCalculator.totalExpense(transactions, previousRange),
      topCategoryChanges: changes.take(3).toList(),
    );
  }
}
