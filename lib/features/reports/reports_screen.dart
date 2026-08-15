import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

final reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final month = ref.watch(reportMonthProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Kategori'),
              Tab(text: 'Cash'),
            ],
          ),
        ),
        body: snapshotAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorStateView(error: error),
          data: (snapshot) {
            final range = DateRange.month(month.year, month.month);
            return Column(
              children: [
                _MonthSelector(
                  month: month,
                  onChanged: (value) =>
                      ref.read(reportMonthProvider.notifier).state = value,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _SummaryTab(
                          snapshot: snapshot, month: month, range: range),
                      _CategoryTab(snapshot: snapshot, range: range),
                      _CashTab(snapshot: snapshot, range: range),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            Formatters.monthYear(month),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          IconButton.filledTonal(
            onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.snapshot,
    required this.month,
    required this.range,
  });

  final FinanceSnapshot snapshot;
  final DateTime month;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    final income = FinanceCalculator.totalIncome(snapshot.transactions, range);
    final expense =
        FinanceCalculator.totalExpense(snapshot.transactions, range);
    final transfer =
        FinanceCalculator.totalTransfer(snapshot.transactions, range);
    final topCategories = FinanceCalculator.breakdownByCategory(
      snapshot.transactions,
      range,
    ).take(5).toList();

    final months = List.generate(
      6,
      (index) => DateTime(month.year, month.month - 5 + index),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: income,
                color: AppColors.income,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: expense,
                color: AppColors.expense,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Arus Kas Bersih',
                value: income - expense,
                color: AppColors.brand,
                icon: Icons.timeline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Transfer (tidak dihitung)',
                value: transfer,
                color: AppColors.transfer,
                icon: Icons.swap_horiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Tren 6 Bulan',
          subtitle: 'Pemasukan vs pengeluaran',
        ),
        SectionCard(
          child: SizedBox(
            height: 200,
            child: _MonthlyBarChart(
              months: months,
              transactions: snapshot.transactions,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Pengeluaran Terbesar'),
        if (topCategories.isEmpty)
          const SectionCard(
            child: Text('Belum ada pengeluaran pada periode ini.'),
          )
        else
          SectionCard(
            child: Column(
              children: [
                for (final entry in topCategories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.categoriesById[entry.categoryId]?.name ??
                                'Tanpa kategori',
                          ),
                        ),
                        Text(
                          '${Formatters.percent(entry.share)}  '
                          '${Formatters.currency(entry.total)}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.months, required this.transactions});

  final List<DateTime> months;
  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final data = months.map((month) {
      final range = DateRange.month(month.year, month.month);
      return (
        month: month,
        income: FinanceCalculator.totalIncome(transactions, range),
        expense: FinanceCalculator.totalExpense(transactions, range),
      );
    }).toList();

    final maxValue = data.fold<double>(
      0,
      (max, item) => [max, item.income, item.expense].reduce((a, b) => a > b ? a : b),
    );

    if (maxValue == 0) {
      return const Center(child: Text('Belum ada data untuk ditampilkan.'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Formatters.monthYear(data[index].month).split(' ').first
                        .substring(0, 3),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              Formatters.compactCurrency(rod.toY),
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].income,
                  color: AppColors.income,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: data[i].expense,
                  color: AppColors.expense,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.snapshot, required this.range});

  final FinanceSnapshot snapshot;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    final entries = FinanceCalculator.breakdownByCategory(
      snapshot.transactions,
      range,
    );

    if (entries.isEmpty) {
      return const EmptyStateView(
        icon: Icons.pie_chart_outline,
        title: 'Belum ada pengeluaran',
        message: 'Catat pengeluaran untuk melihat komposisi per kategori.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        SectionCard(
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 52,
                sections: [
                  for (final entry in entries)
                    PieChartSectionData(
                      value: entry.total,
                      title: Formatters.percent(entry.share),
                      radius: 58,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      color: Color(
                        snapshot.categoriesById[entry.categoryId]?.colorValue ??
                            AppColors.brand.toARGB32(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: Color(
                      snapshot.categoriesById[entry.categoryId]?.colorValue ??
                          AppColors.brand.toARGB32(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      snapshot.categoriesById[entry.categoryId]?.name ??
                          'Tanpa kategori',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(Formatters.percent(entry.share)),
                  const SizedBox(width: 12),
                  Text(
                    Formatters.currency(entry.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CashTab extends StatelessWidget {
  const _CashTab({required this.snapshot, required this.range});

  final FinanceSnapshot snapshot;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    final cash = snapshot.cashAccount;
    if (cash == null) {
      return const EmptyStateView(
        icon: Icons.payments_outlined,
        title: 'Belum ada akun cash',
        message: 'Buat akun bertipe Cash untuk memantau uang fisikmu.',
      );
    }

    final cashIn = FinanceCalculator.inflow(
        snapshot.transactions, cash.id, range);
    final cashOut = FinanceCalculator.outflow(
        snapshot.transactions, cash.id, range);
    final cashExpense = FinanceCalculator.outflow(
      snapshot.transactions,
      cash.id,
      range,
      includeTransfers: false,
    );
    final cashTransactions = snapshot.transactions
        .where((tx) =>
            (tx.accountId == cash.id || tx.destinationAccountId == cash.id) &&
            range.contains(tx.transactionDateTime))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo Cash',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                Formatters.currency(snapshot.balanceOf(cash.id)),
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Cash In',
                value: cashIn,
                color: AppColors.income,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Cash Out',
                value: cashOut,
                color: AppColors.expense,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dari Cash Out di atas, ${Formatters.currency(cashExpense)} '
                  'adalah pengeluaran nyata. Sisanya transfer ke akun lain.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Transaksi Cash'),
        if (cashTransactions.isEmpty)
          const SectionCard(child: Text('Belum ada transaksi cash.'))
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final tx in cashTransactions)
                  ListTile(
                    dense: true,
                    title: Text(tx.title),
                    subtitle:
                        Text(Formatters.dateTime(tx.transactionDateTime)),
                    trailing: Text(
                      Formatters.currency(tx.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
