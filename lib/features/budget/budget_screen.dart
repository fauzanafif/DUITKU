import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

final budgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, month: month),
        icon: const Icon(Icons.add),
        label: const Text('Budget Baru'),
      ),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) => budgetsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorStateView(error: error),
          data: (budgets) {
            final monthly = budgets
                .where((b) => b.year == month.year && b.month == month.month)
                .toList();
            final statuses = monthly
                .map((budget) => FinanceCalculator.budgetStatus(
                    budget, snapshot.transactions))
                .toList()
              ..sort((a, b) => b.ratio.compareTo(a.ratio));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => ref
                            .read(budgetMonthProvider.notifier)
                            .state = DateTime(month.year, month.month - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(Formatters.monthYear(month),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      IconButton.filledTonal(
                        onPressed: () => ref
                            .read(budgetMonthProvider.notifier)
                            .state = DateTime(month.year, month.month + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: statuses.isEmpty
                      ? EmptyStateView(
                          icon: Icons.pie_chart_outline,
                          title: 'Belum ada budget',
                          message:
                              'Tetapkan batas pengeluaran per kategori untuk '
                              'bulan ini.',
                          action: FilledButton.icon(
                            onPressed: () =>
                                _openEditor(context, ref, month: month),
                            icon: const Icon(Icons.add),
                            label: const Text('Buat Budget'),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                          children: [
                            for (final status in statuses)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _BudgetCard(
                                  status: status,
                                  category: snapshot.categoriesById[
                                      status.budget.categoryId],
                                  onEdit: () => _openEditor(context, ref,
                                      month: month, budget: status.budget),
                                  onDelete: () => ref
                                      .read(financeControllerProvider)
                                      .deleteBudget(status.budget.id),
                                ),
                              ),
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

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required DateTime month,
    Budget? budget,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _BudgetEditor(month: month, budget: budget),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.status,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetStatus status;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _color {
    if (status.isOverBudget) return AppColors.expense;
    if (status.isCritical) return const Color(0xFFF97316);
    if (status.isWarning) return AppColors.warning;
    return AppColors.income;
  }

  String? get _warning {
    if (status.isOverBudget) return 'Budget terlampaui!';
    if (status.isCritical) return 'Sudah 90% terpakai.';
    if (status.isWarning) return 'Sudah 80% terpakai.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category?.name ?? 'Kategori terhapus',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(Formatters.percent(status.ratio),
                  style: TextStyle(color: _color, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: status.ratio.clamp(0.0, 1.0),
              minHeight: 10,
              color: _color,
              backgroundColor: _color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terpakai ${Formatters.currency(status.used)} dari '
                  '${Formatters.currency(status.budget.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                status.remaining >= 0
                    ? 'Sisa ${Formatters.currency(status.remaining)}'
                    : 'Lebih ${Formatters.currency(status.remaining.abs())}',
                style: TextStyle(color: _color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_warning != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: _color),
                const SizedBox(width: 6),
                Text(_warning!,
                    style:
                        TextStyle(color: _color, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetEditor extends ConsumerStatefulWidget {
  const _BudgetEditor({required this.month, this.budget});

  final DateTime month;
  final Budget? budget;

  @override
  ConsumerState<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<_BudgetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController = TextEditingController(
    text: widget.budget == null
        ? ''
        : Formatters.thousands(widget.budget!.amount),
  );
  late String? _categoryId = widget.budget?.categoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;
    final categories = snapshot?.categoriesOf(CategoryKind.expense) ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.budget == null ? 'Budget Baru' : 'Edit Budget',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('Periode ${Formatters.monthYear(widget.month)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                        value: category.id, child: Text(category.name)),
                ],
                validator: (value) => value == null ? 'Pilih kategori' : null,
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 14),
              AmountField(controller: _amountController, label: 'Nominal budget'),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(financeControllerProvider);
    final amount = Formatters.parseAmount(_amountController.text);
    try {
      final existing = widget.budget;
      if (existing == null) {
        await controller.createBudget(
          categoryId: _categoryId!,
          amount: amount,
          year: widget.month.year,
          month: widget.month.month,
        );
      } else {
        await controller.saveBudget(
          existing.copyWith(categoryId: _categoryId, amount: amount),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
