enum PeriodPreset { today, thisWeek, thisMonth, lastMonth, thisYear, all, custom }

extension PeriodPresetLabel on PeriodPreset {
  String get label {
    switch (this) {
      case PeriodPreset.today:
        return 'Hari ini';
      case PeriodPreset.thisWeek:
        return 'Minggu ini';
      case PeriodPreset.thisMonth:
        return 'Bulan ini';
      case PeriodPreset.lastMonth:
        return 'Bulan lalu';
      case PeriodPreset.thisYear:
        return 'Tahun ini';
      case PeriodPreset.all:
        return 'Semua';
      case PeriodPreset.custom:
        return 'Custom';
    }
  }
}

/// Half-open date interval `[start, end)`. A null bound means unbounded.
class DateRange {
  const DateRange({this.start, this.end});

  const DateRange.unbounded() : start = null, end = null;

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime moment) {
    if (start != null && moment.isBefore(start!)) return false;
    if (end != null && !moment.isBefore(end!)) return false;
    return true;
  }

  static DateRange month(int year, int month) =>
      DateRange(start: DateTime(year, month), end: DateTime(year, month + 1));

  static DateRange day(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return DateRange(start: start, end: start.add(const Duration(days: 1)));
  }

  /// Inclusive on both ends, as expected from a user-facing custom filter.
  static DateRange between(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    return DateRange(start: start, end: end);
  }

  static DateRange fromPreset(
    PeriodPreset preset, {
    required DateTime now,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    switch (preset) {
      case PeriodPreset.today:
        return DateRange.day(now);
      case PeriodPreset.thisWeek:
        final startOfWeek =
            DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return DateRange(
            start: startOfWeek, end: startOfWeek.add(const Duration(days: 7)));
      case PeriodPreset.thisMonth:
        return DateRange.month(now.year, now.month);
      case PeriodPreset.lastMonth:
        return DateRange.month(now.year, now.month - 1);
      case PeriodPreset.thisYear:
        return DateRange(
            start: DateTime(now.year), end: DateTime(now.year + 1));
      case PeriodPreset.all:
        return const DateRange.unbounded();
      case PeriodPreset.custom:
        if (customFrom == null || customTo == null) {
          return const DateRange.unbounded();
        }
        return DateRange.between(customFrom, customTo);
    }
  }
}
