import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _time = DateFormat('HH:mm', 'id_ID');

  static String currency(double value) => _rupiah.format(value);

  static String signedCurrency(double value) =>
      '${value < 0 ? '-' : '+'} ${_rupiah.format(value.abs())}';

  static String compactCurrency(double value) => _compact.format(value);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String time(DateTime date) => _time.format(date);

  static String dateTime(DateTime date) =>
      '${_fullDate.format(date)} • ${_time.format(date)}';

  static String percent(double ratio) =>
      '${(ratio * 100).toStringAsFixed(0)}%';

  /// Parses digits typed into an amount field ("1.500.000" -> 1500000).
  static double parseAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.parse(digits);
  }

  static String thousands(double value) =>
      NumberFormat.decimalPattern('id_ID').format(value);
}
