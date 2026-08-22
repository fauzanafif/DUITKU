import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:uuid/uuid.dart';

class DebtRepository {
  DebtRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<Debt>> getAll() => _db.readDebts();

  Future<Debt> create({
    required String name,
    required DebtType type,
    required double remainingAmount,
    required int dueDay,
    required int colorValue,
    required int iconCodePoint,
    double? totalAmount,
    double? installmentAmount,
    DateTime? startDate,
    String? accountId,
    bool reminderEnabled = false,
  }) async {
    final now = DateTime.now();
    final debt = Debt(
      id: _uuid.v4(),
      name: name,
      type: type,
      remainingAmount: remainingAmount,
      totalAmount: totalAmount,
      installmentAmount: installmentAmount,
      dueDay: dueDay,
      startDate: startDate,
      accountId: accountId,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      reminderEnabled: reminderEnabled,
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeDebt(debt);
    return debt;
  }

  Future<void> save(Debt debt) => _db.writeDebt(debt);

  Future<void> delete(String id) => _db.deleteDebt(id);
}
