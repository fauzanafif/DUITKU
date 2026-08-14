/// Defensive readers used by [fromJson] factories so a corrupted or
/// partially-written backup file can never crash the app at startup.
class BackupFormatException implements Exception {
  BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

String readString(Map<String, dynamic> json, String key, {String? fallback}) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  if (fallback != null) return fallback;
  throw BackupFormatException('Field "$key" is missing or not a String.');
}

String? readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  return null;
}

double readDouble(Map<String, dynamic> json, String key, {double fallback = 0}) {
  final value = json[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool readBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value is bool) return value;
  return fallback;
}

DateTime readDate(Map<String, dynamic> json, String key, {DateTime? fallback}) {
  final value = json[key];
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (fallback != null) return fallback;
  throw BackupFormatException('Field "$key" is missing or not a date.');
}

T readEnum<T extends Enum>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  T fallback,
) {
  final value = json[key];
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
  }
  return fallback;
}
