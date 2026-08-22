import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:uuid/uuid.dart';

class RecurringRuleRepository {
  RecurringRuleRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<RecurringRule>> getAll() => _db.readRecurringRules();

  Future<RecurringRule> create({
    required String title,
    required TransactionType type,
    required double amount,
    required String accountId,
    required RecurringInterval intervalUnit,
    required int intervalCount,
    required DateTime nextDueDate,
    String? categoryId,
  }) async {
    final now = DateTime.now();
    final rule = RecurringRule(
      id: _uuid.v4(),
      title: title,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      intervalUnit: intervalUnit,
      intervalCount: intervalCount,
      nextDueDate: nextDueDate,
      createdAt: now,
      updatedAt: now,
    );
    await _db.writeRecurringRule(rule);
    return rule;
  }

  Future<void> save(RecurringRule rule) => _db.writeRecurringRule(rule);

  Future<void> delete(String id) => _db.deleteRecurringRule(id);
}
