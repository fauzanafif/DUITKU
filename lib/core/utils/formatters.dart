import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static const List<String> availableCurrencyCodes = ['IDR', 'USD', 'EUR'];

  static String _currencySymbol(String code) => switch (code) {
        'USD' => '\$',
        'EUR' => '€',
        'IDR' || 'ID' => 'Rp ',
        _ => code,
      };

  static String _currencyLocale(String code) => switch (code) {
        'USD' || 'EUR' => 'en_US',
        'IDR' || 'ID' => 'id_ID',
        _ => 'en_US',
      };

  static String _formatCurrencyValue(
    double value, {
    required String currencyCode,
    bool compact = false,
  }) {
    final locale = _currencyLocale(currencyCode);
    final symbol = _currencySymbol(currencyCode);
    final formatted = compact
        ? NumberFormat.compact(locale: locale).format(value)
        : NumberFormat('#,##0.##', locale).format(value);

    if (currencyCode == 'IDR') {
      return 'Rp $formatted';
    }

    return '$symbol$formatted';
  }

  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _time = DateFormat('HH:mm', 'id_ID');

  static String currency(double value, {String currencyCode = 'IDR'}) =>
      _formatCurrencyValue(value, currencyCode: currencyCode);

  static String signedCurrency(double value, {String currencyCode = 'IDR'}) =>
      '${value < 0 ? '-' : '+'} ${_formatCurrencyValue(value.abs(), currencyCode: currencyCode)}';

  static String compactCurrency(double value, {String currencyCode = 'IDR'}) =>
      _formatCurrencyValue(value, currencyCode: currencyCode, compact: true);

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
