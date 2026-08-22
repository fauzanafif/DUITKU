import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:uuid/uuid.dart';

class AllowanceLimitRepository {
  AllowanceLimitRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<AllowanceLimit>> getAll() => _db.readAllowanceLimits();

  Future<AllowanceLimit> create({
    required String accountId,
    required double limitAmount,
    required int year,
    required int month,
  }) async {
    final now = DateTime.now();
    final limit = AllowanceLimit(
      id: _uuid.v4(),
      accountId: accountId,
      limitAmount: limitAmount,
      year: year,
      month: month,
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeAllowanceLimit(limit);
    return limit;
  }

  Future<void> save(AllowanceLimit limit) => _db.writeAllowanceLimit(limit);

  Future<void> delete(String id) => _db.deleteAllowanceLimit(id);
}
