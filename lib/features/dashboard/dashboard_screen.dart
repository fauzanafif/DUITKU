import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/features/shell/home_shell.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';
import 'package:duitku/widgets/transaction_tile.dart';

final dashboardMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final month = ref.watch(dashboardMonthProvider);
    final userName = ref.settings.userName;

    return Scaffold(
      body: SafeArea(
        child: snapshotAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorStateView(
            error: error,
            onRetry: () => ref.invalidate(financeSnapshotProvider),
          ),
          data: (snapshot) {
            final range = DateRange.month(month.year, month.month);
            final income =
                FinanceCalculator.totalIncome(snapshot.transactions, range);
            final expense =
                FinanceCalculator.totalExpense(snapshot.transactions, range);
            final recent = snapshot.transactions.take(6).toList();

            return RefreshIndicator(
              onRefresh: () async => invalidateFinancialDataFrom(ref),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _Greeting(userName: userName),
                  const SizedBox(height: 16),
                  _BalanceCard(
                    total: snapshot.totalBalance,
                    income: income,
                    expense: expense,
                    month: month,
                    currencyCode: ref.settings.currencyCode,
                    onPickMonth: () => _pickMonth(context, ref, month),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Akun',
                    action: TextButton(
                      onPressed: () => context.push('/accounts'),
                      child: const Text('Kelola'),
                    ),
                  ),
                  if (snapshot.accounts.isEmpty)
                    SectionCard(
                      onTap: () => context.push('/accounts'),
                      child: const Row(
                        children: [
                          Icon(Icons.add_card),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text('Belum ada akun. Tambahkan akun '
                                  'pertamamu untuk mulai mencatat.')),
                        ],
                      ),
                    )
                  else
                    _AccountsStrip(
                      snapshot: snapshot,
                      currencyCode: ref.settings.currencyCode,
                    ),
                  const SizedBox(height: 20),
                  const _QuickActions(),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Transaksi Terakhir',
                    action: TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('Lihat semua'),
                    ),
                  ),
                  if (recent.isEmpty)
                    const SectionCard(
                      child: Text(
                        'Belum ada transaksi. Tekan tombol + untuk mencatat '
                        'pemasukan atau pengeluaran pertamamu.',
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final tx in recent)
                            TransactionTile(
                              transaction: tx,
                              accounts: snapshot.accountsById,
                              categories: snapshot.categoriesById,
                              onTap: () =>
                                  context.push('/transactions/detail/${tx.id}'),
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
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih bulan laporan',
    );
    if (picked == null) return;
    ref.read(dashboardMonthProvider.notifier).state =
        DateTime(picked.year, picked.month);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isEmpty ? 'Halo!' : 'Halo, $userName',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Kelola uangmu, capai tujuanmu.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.income,
    required this.expense,
    required this.month,
    required this.currencyCode,
    required this.onPickMonth,
  });

  final double total;
  final double income;
  final double expense;
  final DateTime month;
  final String currencyCode;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Saldo',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                onTap: onPickMonth,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        Formatters.monthYear(month),
                        style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.expand_more, color: scheme.onPrimary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.currency(total, currencyCode: currencyCode),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Pemasukan',
                  value: income,
                  icon: Icons.south_west,
                  currencyCode: currencyCode,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Pengeluaran',
                  value: expense,
                  icon: Icons.north_east,
                  currencyCode: currencyCode,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Sisa',
                  value: income - expense,
                  icon: Icons.savings_outlined,
                  currencyCode: currencyCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.currencyCode,
  });

  final String label;
  final double value;
  final IconData icon;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: onPrimary.withValues(alpha: 0.9), size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              color: onPrimary.withValues(alpha: 0.85), fontSize: 12),
        ),
        Text(
          Formatters.compactCurrency(value, currencyCode: currencyCode),
          style: TextStyle(
            color: onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _AccountsStrip extends StatelessWidget {
  const _AccountsStrip({
    required this.snapshot,
    required this.currencyCode,
  });

  final FinanceSnapshot snapshot;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: snapshot.accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = snapshot.accounts[index];
          final color = Color(account.colorValue);
          return SizedBox(
            width: 170,
            child: SectionCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/accounts'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          AppIcons.resolve(account.iconCodePoint),
                          size: 18,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.currency(snapshot.balanceOf(account.id), currencyCode: currencyCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    Widget item({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Row(
        children: [
          item(
            icon: Icons.atm,
            label: 'Tarik Cash',
            color: AppColors.brand,
            onTap: () => context.push(
              '/transactions/add?type=${TransactionType.transfer.name}&mode=withdraw',
            ),
          ),
          item(
            icon: Icons.pie_chart_outline,
            label: 'Budget',
            color: AppColors.warning,
            onTap: () => context.push('/budget'),
          ),
          item(
            icon: Icons.flag_outlined,
            label: 'Target',
            color: AppColors.income,
            onTap: () => context.push('/savings'),
          ),
          item(
            icon: Icons.add_circle_outline,
            label: 'Tambah',
            color: AppColors.transfer,
            onTap: () => showAddTransactionSheet(context),
          ),
        ],
      ),
    );
  }
}
