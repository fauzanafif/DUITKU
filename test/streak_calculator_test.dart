import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/streak_calculator.dart';
import 'package:duitku/data/models/saving_goal.dart';

void main() {
  SavingGoal goalWith(List<SavingContribution> contributions, {double target = 1000000}) {
    final now = DateTime(2026, 8, 1);
    return SavingGoal(
      id: 'g1',
      name: 'Liburan',
      targetAmount: target,
      contributions: contributions,
      colorValue: 1,
      iconCodePoint: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  SavingContribution contributionOn(DateTime date, {double amount = 10000}) =>
      SavingContribution(id: date.toIso8601String(), amount: amount, date: date);

  test('no contributions means zero streak and no badges achieved', () {
    final goal = goalWith(const []);
    expect(StreakCalculator.currentStreakWeeks(goal), 0);
    expect(StreakCalculator.earnedBadges(goal).every((b) => !b.achieved), isTrue);
  });

  test('a single contribution this week counts as a 1-week streak', () {
    final now = DateTime(2026, 8, 13); // Thursday
    final goal = goalWith([contributionOn(DateTime(2026, 8, 11))]);
    expect(StreakCalculator.currentStreakWeeks(goal, now: now), 1);
  });

  test('4 consecutive weeks of contributions unlock the 4-week badge', () {
    final now = DateTime(2026, 8, 27);
    final goal = goalWith([
      contributionOn(DateTime(2026, 8, 4)),
      contributionOn(DateTime(2026, 8, 11)),
      contributionOn(DateTime(2026, 8, 18)),
      contributionOn(DateTime(2026, 8, 25)),
    ]);
    expect(StreakCalculator.currentStreakWeeks(goal, now: now), 4);
    final streakBadge = StreakCalculator.earnedBadges(goal, now: now)
        .firstWhere((b) => b.kind == SavingBadgeKind.streak4Weeks);
    expect(streakBadge.achieved, isTrue);
  });

  test('a missed week resets the streak to zero', () {
    final now = DateTime(2026, 8, 27);
    final goal = goalWith([
      // Two weeks ago, but nothing last week or this week.
      contributionOn(DateTime(2026, 8, 4)),
    ]);
    expect(StreakCalculator.currentStreakWeeks(goal, now: now), 0);
  });

  test('halfway and completed badges reflect goal progress', () {
    final halfway = goalWith([contributionOn(DateTime(2026, 8, 1), amount: 500000)]);
    final completed = goalWith([contributionOn(DateTime(2026, 8, 1), amount: 1000000)]);

    final halfwayBadges = StreakCalculator.earnedBadges(halfway);
    expect(
      halfwayBadges.firstWhere((b) => b.kind == SavingBadgeKind.halfway).achieved,
      isTrue,
    );
    expect(
      halfwayBadges.firstWhere((b) => b.kind == SavingBadgeKind.completed).achieved,
      isFalse,
    );

    final completedBadges = StreakCalculator.earnedBadges(completed);
    expect(
      completedBadges.firstWhere((b) => b.kind == SavingBadgeKind.completed).achieved,
      isTrue,
    );
  });
}
