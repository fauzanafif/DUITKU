import 'package:flutter/material.dart';

import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';

Color transactionColor(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return AppColors.income;
    case TransactionType.expense:
      return AppColors.expense;
    case TransactionType.transfer:
      return AppColors.transfer;
  }
}

IconData transactionIcon(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return Icons.south_west;
    case TransactionType.expense:
      return Icons.north_east;
    case TransactionType.transfer:
      return Icons.swap_horiz;
  }
}

String signedAmountLabel(TransactionRecord tx, {String currencyCode = 'IDR'}) {
  switch (tx.type) {
    case TransactionType.income:
      return '+ ${Formatters.currency(tx.amount, currencyCode: currencyCode)}';
    case TransactionType.expense:
      return '- ${Formatters.currency(tx.amount, currencyCode: currencyCode)}';
    case TransactionType.transfer:
      return Formatters.currency(tx.amount, currencyCode: currencyCode);
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accounts,
    required this.categories,
    this.currencyCode = 'IDR',
    this.onTap,
    this.showTime = true,
  });

  final TransactionRecord transaction;
  final Map<String, Account> accounts;
  final Map<String, Category> categories;
  final String currencyCode;
  final VoidCallback? onTap;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = transactionColor(transaction.type);
    final source = accounts[transaction.accountId];
    final destination = accounts[transaction.destinationAccountId];
    final category = categories[transaction.categoryId];

    final subtitle = transaction.isTransfer
        ? '${source?.name ?? '-'} → ${destination?.name ?? '-'}'
        : '${category?.name ?? 'Tanpa kategori'} • ${source?.name ?? '-'}';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(transactionIcon(transaction.type), color: color, size: 22),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        showTime
            ? '$subtitle • ${Formatters.time(transaction.transactionDateTime)}'
            : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            signedAmountLabel(transaction, currencyCode: currencyCode),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (transaction.isTransfer)
            Text(
              'Transfer',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
