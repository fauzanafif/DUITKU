import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

class AllowanceScreen extends ConsumerStatefulWidget {
  const AllowanceScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AllowanceScreen> createState() => _AllowanceScreenState();
}

class _AllowanceScreenState extends ConsumerState<AllowanceScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final limitsAsync = ref.watch(allowanceLimitsProvider);
    final payday = ref.settings.payday;
    final currencyCode = ref.settings.currencyCode;

    _month ??= () {
      final label = DateRange.financialMonthLabel(DateTime.now(), payday);
      return DateTime(label.year, label.month);
    }();
    final month = _month!;

    return Scaffold(
      appBar: AppBar(title: const Text('Uang Jajan')),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) {
          final account = snapshot.accountsById[widget.accountId];
          if (account == null) {
            return const EmptyStateView(
              icon: Icons.error_outline,
              title: 'Akun tidak ditemukan',
            );
          }
          return limitsAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorStateView(error: error),
            data: (limits) {
              final limit = limits
                  .where((l) =>
                      l.accountId == widget.accountId &&
                      l.year == month.year &&
                      l.month == month.month)
                  .firstOrNull;
              final range =
                  DateRange.financialMonth(month.year, month.month, payday);
              final used = FinanceCalculator.outflow(
                snapshot.transactions,
                widget.accountId,
                range,
                includeTransfers: false,
              );
              final transactions = snapshot.transactions
                  .where((tx) =>
                      tx.accountId == widget.accountId &&
                      range.contains(tx.transactionDateTime))
                  .toList()
                ..sort((a, b) =>
                    b.transactionDateTime.compareTo(a.transactionDateTime));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => setState(() => _month =
                              DateTime(month.year, month.month - 1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          Formatters.monthYear(month),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => _month =
                              DateTime(month.year, month.month + 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _editLimit(context, limit),
                              child: Text(
                                  limit == null ? 'Atur Limit' : 'Ubah Limit'),
                            ),
                          ],
                        ),
                        if (limit == null)
                          Text(
                            'Belum ada limit bulan ini. Terpakai: '
                            '${Formatters.currency(used, currencyCode: currencyCode)}.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: limit.limitAmount <= 0
                                  ? 0
                                  : (used / limit.limitAmount).clamp(0.0, 1.0),
                              minHeight: 10,
                              color: used > limit.limitAmount
                                  ? AppColors.expense
                                  : AppColors.income,
                              backgroundColor: AppColors.income
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Terpakai ${Formatters.currency(used, currencyCode: currencyCode)} dari '
                            '${Formatters.currency(limit.limitAmount, currencyCode: currencyCode)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Transaksi Bulan Ini'),
                  if (transactions.isEmpty)
                    const SectionCard(
                        child: Text('Belum ada transaksi bulan ini.'))
                  else
                    SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (final tx in transactions)
                            ListTile(
                              dense: true,
                              title: Text(tx.title),
                              subtitle: Text(
                                  Formatters.dateTime(tx.transactionDateTime)),
                              trailing: Text(
                                Formatters.currency(tx.amount,
                                    currencyCode: currencyCode),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editLimit(BuildContext context, AllowanceLimit? limit) async {
    final controller = TextEditingController(
      text: limit == null ? '' : Formatters.thousands(limit.limitAmount),
    );
    final formKey = GlobalKey<FormState>();
    final month = _month!;

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Limit ${Formatters.monthYear(month)}'),
        content: Form(
          key: formKey,
          child: AmountField(controller: controller, autofocus: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogContext)
                  .pop(Formatters.parseAmount(controller.text));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;

    final financeController = ref.read(financeControllerProvider);
    if (limit != null) {
      await financeController.saveAllowanceLimit(
          limit.copyWith(limitAmount: amount));
    } else {
      await financeController.createAllowanceLimit(
        accountId: widget.accountId,
        limitAmount: amount,
        year: month.year,
        month: month.month,
      );
    }
  }
}
