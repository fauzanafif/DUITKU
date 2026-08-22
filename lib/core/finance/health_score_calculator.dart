import 'package:duitku/core/finance/finance_calculator.dart';

enum HealthScoreLevel { poor, fair, good, great }

extension HealthScoreLevelLabel on HealthScoreLevel {
  String get label => switch (this) {
        HealthScoreLevel.poor => 'Perlu Perhatian',
        HealthScoreLevel.fair => 'Cukup',
        HealthScoreLevel.good => 'Baik',
        HealthScoreLevel.great => 'Sangat Baik',
      };
}

/// A simple 0-100 snapshot of this month's financial habits, built only
/// from numbers the app already tracks — no new data entry required.
class HealthScore {
  const HealthScore({
    required this.score,
    required this.savingsRatio,
    required this.expenseRatio,
    required this.budgetAdherence,
  });

  final int score;

  /// (income - expense) / income. Can be negative when overspending.
  final double savingsRatio;

  /// expense / income. 0 when there is no income.
  final double expenseRatio;

  /// Fraction (0..1) of this month's budgets that are not over their limit.
  /// 1.0 when there are no budgets set.
  final double budgetAdherence;

  HealthScoreLevel get level {
    if (score >= 80) return HealthScoreLevel.great;
    if (score >= 60) return HealthScoreLevel.good;
    if (score >= 40) return HealthScoreLevel.fair;
    return HealthScoreLevel.poor;
  }
}

class HealthScoreCalculator {
  const HealthScoreCalculator._();

  /// Weighting: 50% how much of income is kept, 30% how lean spending is
  /// relative to income, 20% how well budgets are respected.
  static HealthScore compute({
    required double income,
    required double expense,
    required List<BudgetStatus> budgetStatuses,
  }) {
    final savingsRatio =
        income <= 0 ? 0.0 : ((income - expense) / income).clamp(-1.0, 1.0);
    final expenseRatio =
        income <= 0 ? (expense > 0 ? 1.0 : 0.0) : (expense / income);

    final budgetAdherence = budgetStatuses.isEmpty
        ? 1.0
        : budgetStatuses.where((s) => !s.isOverBudget).length /
            budgetStatuses.length;

    // Saving 30%+ of income earns full marks on this component.
    final savingsComponent = (savingsRatio / 0.3).clamp(0.0, 1.0);
    // Spending at or below 70% of income earns full marks; spending at or
    // above 120% earns none.
    final expenseComponent =
        (1 - ((expenseRatio - 0.7) / 0.5)).clamp(0.0, 1.0);

    final rawScore =
        savingsComponent * 50 + expenseComponent * 30 + budgetAdherence * 20;

    return HealthScore(
      score: rawScore.round().clamp(0, 100),
      savingsRatio: savingsRatio,
      expenseRatio: expenseRatio,
      budgetAdherence: budgetAdherence,
    );
  }
}
