import 'package:duitku/core/utils/json_utils.dart';

enum LogModule { transaksi, kategori, budget, rekening }

extension LogModuleLabel on LogModule {
  String get label {
    switch (this) {
      case LogModule.transaksi:
        return 'Transaksi';
      case LogModule.kategori:
        return 'Kategori';
      case LogModule.budget:
        return 'Budget';
      case LogModule.rekening:
        return 'Rekening';
    }
  }
}

enum LogAction { create, update, delete }

extension LogActionLabel on LogAction {
  String get label {
    switch (this) {
      case LogAction.create:
        return 'Tambah';
      case LogAction.update:
        return 'Ubah';
      case LogAction.delete:
        return 'Hapus';
    }
  }
}

/// A single, immutable audit-trail record. Once written it is never edited
/// or deleted — the Activity Log survives every clear/restore of the
/// financial data, so it deliberately has no `copyWith`.
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.module,
    required this.action,
    required this.entityName,
    this.detail,
  });

  final String id;
  final DateTime timestamp;
  final LogModule module;
  final LogAction action;
  final String entityName;

  /// Human-readable summary of what changed, e.g. `Rp 50.000 → Rp 75.000`.
  final String? detail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'module': module.name,
        'action': action.name,
        'entityName': entityName,
        'detail': detail,
      };

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      ActivityLogEntry(
        id: readString(json, 'id'),
        timestamp: readDate(json, 'timestamp'),
        module: readEnum(json, 'module', LogModule.values, LogModule.transaksi),
        action: readEnum(json, 'action', LogAction.values, LogAction.create),
        entityName: readString(json, 'entityName', fallback: '-'),
        detail: readNullableString(json, 'detail'),
      );
}
