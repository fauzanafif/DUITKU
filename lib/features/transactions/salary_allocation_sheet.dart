import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/allocation_calculator.dart';
import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/app_settings.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/widgets/amount_field.dart';

/// Shown right after saving an income transaction, when allocation is
/// enabled. "Alokasikan" sets/updates this cycle's Budget for each of the
/// three categories to the split amount — it never books a transaction or
/// touches any account balance, so the paycheck still shows up as real
/// money in the account; the split is purely a spending *limit* for the
/// cycle, tracked the same way any other Budget already is.
Future<void> showSalaryAllocationSheet(
  BuildContext context, {
  required double amount,
  required DateTime date,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _SalaryAllocationSheet(amount: amount, date: date),
    ),
  );
}

class _SalaryAllocationSheet extends ConsumerStatefulWidget {
  const _SalaryAllocationSheet({required this.amount, required this.date});

  final double amount;
  final DateTime date;

  @override
  ConsumerState<_SalaryAllocationSheet> createState() =>
      _SalaryAllocationSheetState();
}

class _SalaryAllocationSheetState
    extends ConsumerState<_SalaryAllocationSheet> {
  late final TextEditingController _needsController;
  late final TextEditingController _wantsController;
  late final TextEditingController _savingsController;
  bool _prefilled = false;
  bool _saving = false;

  void _prefill(AppSettings settings) {
    if (_prefilled) return;
    _prefilled = true;
    final split = AllocationCalculator.split(
      widget.amount,
      needsPercent: settings.allocationNeedsPercent,
      wantsPercent: settings.allocationWantsPercent,
      savingsPercent: settings.allocationSavingsPercent,
    );
    _needsController =
        TextEditingController(text: Formatters.thousands(split.needs));
    _wantsController =
        TextEditingController(text: Formatters.thousands(split.wants));
    _savingsController =
        TextEditingController(text: Formatters.thousands(split.savings));
  }

  @override
  void dispose() {
    _needsController.dispose();
    _wantsController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.settings;
    _prefill(settings);
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;

    final needsCategory =
        snapshot?.categoriesById[settings.allocationNeedsCategoryId];
    final wantsCategory =
        snapshot?.categoriesById[settings.allocationWantsCategoryId];
    final savingsCategory =
        snapshot?.categoriesById[settings.allocationSavingsCategoryId];
    final categoriesReady =
        needsCategory != null && wantsCategory != null && savingsCategory != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alokasikan Gaji Ini?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.currency(widget.amount, currencyCode: settings.currencyCode)} '
              'akan dipecah jadi budget bulan ini sesuai persentase yang '
              'kamu atur. Saldo akunmu tidak berubah — ini cuma batas '
              'pengeluaran, bukan transaksi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!categoriesReady)
              Text(
                'Kategori alokasi belum lengkap diatur. Atur dulu di '
                'Pengaturan > Alokasi Gaji Otomatis.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else ...[
              AmountField(
                controller: _needsController,
                label: 'Kebutuhan (${needsCategory.name})',
              ),
              const SizedBox(height: 12),
              AmountField(
                controller: _wantsController,
                label: 'Keinginan (${wantsCategory.name})',
              ),
              const SizedBox(height: 12),
              AmountField(
                controller: _savingsController,
                label: 'Tabungan (${savingsCategory.name})',
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: !categoriesReady || _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Alokasikan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final settings = ref.settings;
    final label = DateRange.financialMonthLabel(widget.date, settings.payday);
    final budgets = ref.read(budgetsProvider).valueOrNull ?? const <Budget>[];
    final controller = ref.read(financeControllerProvider);

    final entries = [
      (settings.allocationNeedsCategoryId,
          Formatters.parseAmount(_needsController.text)),
      (settings.allocationWantsCategoryId,
          Formatters.parseAmount(_wantsController.text)),
      (settings.allocationSavingsCategoryId,
          Formatters.parseAmount(_savingsController.text)),
    ];

    for (final (categoryId, amount) in entries) {
      if (categoryId == null || amount <= 0) continue;
      final existing = budgets
          .where((b) =>
              b.categoryId == categoryId &&
              b.year == label.year &&
              b.month == label.month)
          .firstOrNull;
      if (existing != null) {
        await controller.saveBudget(existing.copyWith(amount: amount));
      } else {
        await controller.createBudget(
          categoryId: categoryId,
          amount: amount,
          year: label.year,
          month: label.month,
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
