import 'package:duitku/data/models/saving_goal.dart';

enum SavingBadgeKind { firstContribution, streak4Weeks, halfway, completed }

extension SavingBadgeKindLabel on SavingBadgeKind {
  String get label {
    switch (this) {
      case SavingBadgeKind.firstContribution:
        return 'Kontribusi Pertama';
      case SavingBadgeKind.streak4Weeks:
        return 'Konsisten 4 Minggu';
      case SavingBadgeKind.halfway:
        return '50% Tercapai';
      case SavingBadgeKind.completed:
        return 'Goal Tercapai';
    }
  }
}

class SavingBadgeStatus {
  const SavingBadgeStatus({required this.kind, required this.achieved});

  final SavingBadgeKind kind;
  final bool achieved;
}

/// Streak and badges are derived live from `SavingGoal.contributions` —
/// nothing new is persisted, so there is nothing to keep in sync.
class StreakCalculator {
  const StreakCalculator._();

  static DateTime _startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Consecutive weeks up to and including the current week that have at
  /// least one contribution. Zero as soon as a week is missed.
  static int currentStreakWeeks(SavingGoal goal, {DateTime? now}) {
    if (goal.contributions.isEmpty) return 0;

    final weeksWithContribution = <DateTime>{
      for (final contribution in goal.contributions)
        _startOfWeek(contribution.date),
    };

    var streak = 0;
    var cursor = _startOfWeek(now ?? DateTime.now());
    while (weeksWithContribution.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return streak;
  }

  static List<SavingBadgeStatus> earnedBadges(SavingGoal goal, {DateTime? now}) {
    final streakWeeks = currentStreakWeeks(goal, now: now);
    return [
      SavingBadgeStatus(
        kind: SavingBadgeKind.firstContribution,
        achieved: goal.contributions.isNotEmpty,
      ),
      SavingBadgeStatus(
        kind: SavingBadgeKind.streak4Weeks,
        achieved: streakWeeks >= 4,
      ),
      SavingBadgeStatus(
        kind: SavingBadgeKind.halfway,
        achieved: goal.progress >= 0.5,
      ),
      SavingBadgeStatus(
        kind: SavingBadgeKind.completed,
        achieved: goal.progress >= 1.0,
      ),
    ];
  }
}
