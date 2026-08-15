import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:uuid/uuid.dart';

class BudgetRepository {
  BudgetRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<Budget>> getAll() => _db.readBudgets();

  Future<Budget> create({
    required String categoryId,
    required double amount,
    required int year,
    required int month,
  }) async {
    final existing = await _db.readBudgets();
    final duplicate = existing.where((b) =>
        b.categoryId == categoryId && b.year == year && b.month == month);
    if (duplicate.isNotEmpty) {
      throw StateError('Budget kategori ini untuk periode tersebut sudah ada.');
    }
    final now = DateTime.now();
    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      year: year,
      month: month,
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeBudget(budget);
    return budget;
  }

  Future<void> save(Budget budget) => _db.writeBudget(budget);

  Future<void> delete(String id) => _db.deleteBudget(id);
}
