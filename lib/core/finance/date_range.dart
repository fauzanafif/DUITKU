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

  /// The pay-cycle labeled (year, month): starts on [payday] of that month,
  /// ends the day before [payday] of the following month. `payday: 1`
  /// matches [month] exactly, so this is a strict generalization — every
  /// existing user who never touches the payday setting sees no change.
  ///
  /// [payday] is clamped to the last day of a shorter month (e.g. 31 in
  /// February), the same way `Debt.dueDay` already is.
  static DateRange financialMonth(int year, int month, int payday) {
    DateTime clampedStart(int y, int m) {
      final lastDay = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, payday.clamp(1, lastDay));
    }

    return DateRange(
      start: clampedStart(year, month),
      end: clampedStart(year, month + 1),
    );
  }

  /// The (year, month) label of the [financialMonth] cycle that contains
  /// [moment]. Needed because if [moment] falls before this calendar
  /// month's payday, it actually still belongs to the cycle labeled the
  /// *previous* month.
  static ({int year, int month}) financialMonthLabel(
    DateTime moment,
    int payday,
  ) {
    final thisMonthCycle = financialMonth(moment.year, moment.month, payday);
    if (moment.isBefore(thisMonthCycle.start!)) {
      final previous = DateTime(moment.year, moment.month - 1);
      return (year: previous.year, month: previous.month);
    }
    return (year: moment.year, month: moment.month);
  }

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
    int payday = 1,
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
        final label = financialMonthLabel(now, payday);
        return DateRange.financialMonth(label.year, label.month, payday);
      case PeriodPreset.lastMonth:
        final thisLabel = financialMonthLabel(now, payday);
        final previous = DateTime(thisLabel.year, thisLabel.month - 1);
        return DateRange.financialMonth(previous.year, previous.month, payday);
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
