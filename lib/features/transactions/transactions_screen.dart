import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/features/transactions/transaction_filter.dart';
import 'package:duitku/widgets/state_views.dart';
import 'package:duitku/widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            tooltip: filter.newestFirst ? 'Terbaru dulu' : 'Terlama dulu',
            onPressed: () => ref
                .read(transactionFilterProvider.notifier)
                .update((state) => state.copyWith(newestFirst: !state.newestFirst)),
            icon: Icon(filter.newestFirst
                ? Icons.arrow_downward
                : Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: () => _openFilterSheet(context),
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) {
          final filtered =
              filter.apply(snapshot.transactions, payday: ref.settings.payday);
          final grouped = FinanceCalculator.groupByDay(filtered);
          final days = grouped.keys.toList()
            ..sort((a, b) => filter.newestFirst ? b.compareTo(a) : a.compareTo(b));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau catatan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .update((state) => state.copyWith(query: ''));
                            },
                          ),
                  ),
                  onChanged: (value) => ref
                      .read(transactionFilterProvider.notifier)
                      .update((state) => state.copyWith(query: value)),
                ),
              ),
              _SummaryStrip(transactions: filtered),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'Tidak ada transaksi',
                        message:
                            'Coba ubah filter atau catat transaksi baru lewat tombol +.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 120),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final items = grouped[day]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 8, 8, 6),
                                  child: Text(
                                    Formatters.fullDate(day),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Card(
                                  child: Column(
                                    children: [
                                      for (final tx in items)
                                        TransactionTile(
                                          transaction: tx,
                                          accounts: snapshot.accountsById,
                                          categories: snapshot.categoriesById,
                                          onTap: () => context.push(
                                              '/transactions/detail/${tx.id}'),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    const range = DateRange.unbounded();
    final income = FinanceCalculator.totalIncome(transactions, range);
    final expense = FinanceCalculator.totalExpense(transactions, range);
    final transfer = FinanceCalculator.totalTransfer(transactions, range);

    Widget item(String label, double value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(
                Formatters.compactCurrency(value, currencyCode: 'IDR'),
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          item('Pemasukan', income, AppColors.income),
          item('Pengeluaran', expense, AppColors.expense),
          item('Transfer', transfer, AppColors.transfer),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;
    final notifier = ref.read(transactionFilterProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filter Transaksi',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () =>
                        notifier.state = TransactionFilter(query: filter.query),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: filter.type == null,
                    onSelected: (_) =>
                        notifier.update((s) => s.copyWith(type: null)),
                  ),
                  for (final type in TransactionType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      selected: filter.type == type,
                      onSelected: (_) =>
                          notifier.update((s) => s.copyWith(type: type)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Akun', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: filter.accountId == null,
                    onSelected: (_) =>
                        notifier.update((s) => s.copyWith(accountId: null)),
                  ),
                  for (final account in snapshot?.accounts ?? [])
                    ChoiceChip(
                      label: Text(account.name),
                      selected: filter.accountId == account.id,
                      onSelected: (_) => notifier
                          .update((s) => s.copyWith(accountId: account.id)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Periode',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in PeriodPreset.values)
                    ChoiceChip(
                      label: Text(preset.label),
                      selected: filter.period == preset,
                      onSelected: (_) async {
                        if (preset == PeriodPreset.custom) {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            helpText: 'Pilih rentang tanggal',
                          );
                          if (picked == null) return;
                          notifier.update((s) => s.copyWith(
                                period: PeriodPreset.custom,
                                customFrom: picked.start,
                                customTo: picked.end,
                              ));
                          return;
                        }
                        notifier.update((s) => s.copyWith(period: preset));
                      },
                    ),
                ],
              ),
              if (filter.period == PeriodPreset.custom &&
                  filter.customFrom != null &&
                  filter.customTo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${Formatters.shortDate(filter.customFrom!)} - '
                    '${Formatters.shortDate(filter.customTo!)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terapkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
