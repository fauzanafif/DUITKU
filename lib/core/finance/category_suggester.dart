import 'package:duitku/data/models/transaction.dart';

/// Suggests a category for a new transaction by looking at how similarly
/// titled transactions were categorized before. Never forces a choice —
/// returns null whenever there isn't a confident match.
class CategorySuggester {
  const CategorySuggester._();

  static const _minTitleLength = 3;

  static String? suggest(
    String title,
    Iterable<TransactionRecord> history,
    TransactionType type,
  ) {
    final normalized = _normalize(title);
    if (normalized.length < _minTitleLength) return null;

    final counts = <String, int>{};
    for (final tx in history) {
      if (tx.type != type) continue;
      final categoryId = tx.categoryId;
      if (categoryId == null) continue;

      final txTitle = _normalize(tx.title);
      if (txTitle.length < _minTitleLength) continue;

      if (txTitle == normalized ||
          txTitle.contains(normalized) ||
          normalized.contains(txTitle)) {
        counts.update(categoryId, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
