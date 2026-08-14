import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/data/models/transaction.dart';

class TransactionFilter {
  const TransactionFilter({
    this.query = '',
    this.type,
    this.accountId,
    this.categoryId,
    this.period = PeriodPreset.all,
    this.customFrom,
    this.customTo,
    this.newestFirst = true,
  });

  final String query;
  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final PeriodPreset period;
  final DateTime? customFrom;
  final DateTime? customTo;
  final bool newestFirst;

  bool get isActive =>
      type != null ||
      accountId != null ||
      categoryId != null ||
      period != PeriodPreset.all;

  DateRange range({DateTime? now}) => DateRange.fromPreset(
        period,
        now: now ?? DateTime.now(),
        customFrom: customFrom,
        customTo: customTo,
      );

  TransactionFilter copyWith({
    String? query,
    Object? type = _unset,
    Object? accountId = _unset,
    Object? categoryId = _unset,
    PeriodPreset? period,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    bool? newestFirst,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      type: type == _unset ? this.type : type as TransactionType?,
      accountId: accountId == _unset ? this.accountId : accountId as String?,
      categoryId:
          categoryId == _unset ? this.categoryId : categoryId as String?,
      period: period ?? this.period,
      customFrom:
          customFrom == _unset ? this.customFrom : customFrom as DateTime?,
      customTo: customTo == _unset ? this.customTo : customTo as DateTime?,
      newestFirst: newestFirst ?? this.newestFirst,
    );
  }

  List<TransactionRecord> apply(
    List<TransactionRecord> transactions, {
    DateTime? now,
  }) {
    final dateRange = range(now: now);
    final normalizedQuery = query.trim().toLowerCase();
    final result = transactions.where((tx) {
      if (!dateRange.contains(tx.transactionDateTime)) return false;
      if (type != null && tx.type != type) return false;
      if (accountId != null &&
          tx.accountId != accountId &&
          tx.destinationAccountId != accountId) {
        return false;
      }
      if (categoryId != null && tx.categoryId != categoryId) return false;
      if (normalizedQuery.isNotEmpty) {
        final haystack =
            '${tx.title} ${tx.note ?? ''}'.toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => newestFirst
        ? b.transactionDateTime.compareTo(a.transactionDateTime)
        : a.transactionDateTime.compareTo(b.transactionDateTime));
    return result;
  }
}

const Object _unset = Object();

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());
