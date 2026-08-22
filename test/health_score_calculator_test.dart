import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/finance/health_score_calculator.dart';
import 'package:duitku/data/models/budget.dart';

void main() {
  test('healthy savings and lean spending score near the top', () {
    final score = HealthScoreCalculator.compute(
      income: 10000000,
      expense: 5000000,
      budgetStatuses: const [],
    );

    expect(score.score, 100);
    expect(score.level, HealthScoreLevel.great);
  });

  test('overspending scores low', () {
    final score = HealthScoreCalculator.compute(
      income: 5000000,
      expense: 5500000,
      budgetStatuses: const [],
    );

    expect(score.savingsRatio, lessThan(0));
    expect(score.level, HealthScoreLevel.poor);
  });

  test('an over-budget category drags the score down', () {
    final now = DateTime(2026, 8);
    final budget = Budget(
      id: 'b1',
      categoryId: 'makanan',
      amount: 500000,
      year: 2026,
      month: 8,
      createdAt: now,
      updatedAt: now,
    );
    final overBudget = BudgetStatus(budget: budget, used: 600000);

    final scoreWithOverBudget = HealthScoreCalculator.compute(
      income: 10000000,
      expense: 5000000,
      budgetStatuses: [overBudget],
    );
    final scoreWithoutBudgets = HealthScoreCalculator.compute(
      income: 10000000,
      expense: 5000000,
      budgetStatuses: const [],
    );

    expect(scoreWithOverBudget.budgetAdherence, 0);
    expect(scoreWithOverBudget.score, lessThan(scoreWithoutBudgets.score));
  });

  test('no income and no expense is treated neutrally, not as an error', () {
    final score = HealthScoreCalculator.compute(
      income: 0,
      expense: 0,
      budgetStatuses: const [],
    );

    expect(score.score, inInclusiveRange(0, 100));
  });
}
