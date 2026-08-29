import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/data/models/activity_log_entry.dart';

/// In-memory filter for the Activity Log. The number of entries for a
/// personal finance app stays small, so filtering the full list is fine —
/// no dedicated database query needed. Mirrors the shape of
/// `TransactionFilter`.
class LogFilter {
  const LogFilter({
    this.query = '',
    this.action,
    this.module,
    this.dateFrom,
    this.dateTo,
  });

  final String query;
  final LogAction? action;
  final LogModule? module;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isActive =>
      action != null ||
      module != null ||
      dateFrom != null ||
      dateTo != null;

  LogFilter copyWith({
    String? query,
    Object? action = _unset,
    Object? module = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
  }) {
    return LogFilter(
      query: query ?? this.query,
      action: action == _unset ? this.action : action as LogAction?,
      module: module == _unset ? this.module : module as LogModule?,
      dateFrom: dateFrom == _unset ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _unset ? this.dateTo : dateTo as DateTime?,
    );
  }

  List<ActivityLogEntry> apply(List<ActivityLogEntry> entries) {
    final normalizedQuery = query.trim().toLowerCase();
    final from = dateFrom == null
        ? null
        : DateTime(dateFrom!.year, dateFrom!.month, dateFrom!.day);
    final to = dateTo == null
        ? null
        : DateTime(dateTo!.year, dateTo!.month, dateTo!.day, 23, 59, 59, 999);

    final result = entries.where((entry) {
      if (from != null && entry.timestamp.isBefore(from)) return false;
      if (to != null && entry.timestamp.isAfter(to)) return false;
      if (action != null && entry.action != action) return false;
      if (module != null && entry.module != module) return false;
      if (normalizedQuery.isNotEmpty) {
        final haystack =
            '${entry.entityName} ${entry.detail ?? ''}'.toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }
}

const Object _unset = Object();

final logFilterProvider =
    StateProvider<LogFilter>((ref) => const LogFilter());
