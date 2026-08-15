import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:uuid/uuid.dart';

class SavingGoalRepository {
  SavingGoalRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<SavingGoal>> getAll() async {
    final goals = await _db.readSavingGoals();
    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return goals;
  }

  Future<SavingGoal> create({
    required String name,
    required double targetAmount,
    required int colorValue,
    required int iconCodePoint,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final goal = SavingGoal(
      id: _uuid.v4(),
      name: name.trim(),
      targetAmount: targetAmount,
      contributions: const [],
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeSavingGoal(goal);
    return goal;
  }

  Future<void> save(SavingGoal goal) => _db.writeSavingGoal(goal);

  Future<void> delete(String id) => _db.deleteSavingGoal(id);

  Future<SavingGoal> addContribution(
    SavingGoal goal, {
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final updated = goal.copyWith(
      contributions: [
        ...goal.contributions,
        SavingContribution(
          id: _uuid.v4(),
          amount: amount,
          date: date,
          note: note,
        ),
      ],
    );
    await _db.writeSavingGoal(updated);
    return updated;
  }

  Future<SavingGoal> removeContribution(
    SavingGoal goal,
    String contributionId,
  ) async {
    final updated = goal.copyWith(
      contributions:
          goal.contributions.where((c) => c.id != contributionId).toList(),
    );
    await _db.writeSavingGoal(updated);
    return updated;
  }
}
