import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:uuid/uuid.dart';

/// Append-only store for the Activity Log. There is intentionally no
/// `update` or `delete` — entries are a permanent audit trail.
class ActivityLogRepository {
  ActivityLogRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<ActivityLogEntry>> getAll() async {
    final logs = await _db.readActivityLogs();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<ActivityLogEntry> add({
    required LogModule module,
    required LogAction action,
    required String entityName,
    String? detail,
  }) async {
    final entry = ActivityLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      module: module,
      action: action,
      entityName: entityName,
      detail: detail,
    );
    await _db.writeActivityLog(entry);
    return entry;
  }
}
