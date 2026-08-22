import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';
import 'package:duitku/widgets/transaction_tile.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRecurringEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: rulesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyStateView(
              icon: Icons.autorenew,
              title: 'Belum ada transaksi berulang',
              message: 'Catat langganan atau tagihan rutin biar diingatkan '
                  'setiap jatuh tempo.',
              action: FilledButton.icon(
                onPressed: () => openRecurringEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            );
          }

          final due = rules.where((r) => r.isDue).toList()
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          final upcoming = rules
              .where((r) => r.isActive && !r.isDue)
              .toList()
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          final inactive = rules.where((r) => !r.isActive).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              if (due.isNotEmpty) ...[
                const SectionHeader(title: 'Perlu Dikonfirmasi'),
                for (final rule in due)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DueRuleCard(rule: rule),
                  ),
              ],
              if (upcoming.isNotEmpty) ...[
                const SectionHeader(title: 'Akan Datang'),
                for (final rule in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RuleCard(rule: rule),
                  ),
              ],
              if (inactive.isNotEmpty) ...[
                const SectionHeader(title: 'Nonaktif'),
                for (final rule in inactive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RuleCard(rule: rule),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> openRecurringEditor(BuildContext context, {RecurringRule? rule}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _RecurringEditor(rule: rule),
    ),
  );
}

class _DueRuleCard extends ConsumerWidget {
  const _DueRuleCard({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.settings.currencyCode;
    final color = transactionColor(rule.type);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(transactionIcon(rule.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      'Jatuh tempo ${Formatters.shortDate(rule.nextDueDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.currency(rule.amount, currencyCode: currencyCode),
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  onPressed: () => ref
                      .read(financeControllerProvider)
                      .skipRecurring(rule),
                  child: const Text('Lewati'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  onPressed: () => ref
                      .read(financeControllerProvider)
                      .confirmRecurring(rule),
                  child: const Text('Konfirmasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  const _RuleCard({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.settings.currencyCode;
    final color = transactionColor(rule.type);

    return SectionCard(
      onTap: () => openRecurringEditor(context, rule: rule),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: rule.isActive ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transactionIcon(rule.type),
              color: rule.isActive ? color : Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  rule.isActive
                      ? 'Setiap ${rule.intervalCount} ${rule.intervalUnit.label.toLowerCase()} • '
                          '${Formatters.shortDate(rule.nextDueDate)}'
                      : 'Nonaktif',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(rule.amount, currencyCode: currencyCode),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RecurringEditor extends ConsumerStatefulWidget {
  const _RecurringEditor({this.rule});

  final RecurringRule? rule;

  @override
  ConsumerState<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends ConsumerState<_RecurringEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.rule?.title ?? '');
  late final TextEditingController _amountController = TextEditingController(
    text: widget.rule == null ? '' : Formatters.thousands(widget.rule!.amount),
  );

  late TransactionType _type = widget.rule?.type ?? TransactionType.expense;
  String? _accountId;
  String? _categoryId;
  late RecurringInterval _intervalUnit =
      widget.rule?.intervalUnit ?? RecurringInterval.monthly;
  late int _intervalCount = widget.rule?.intervalCount ?? 1;
  late DateTime _nextDueDate = widget.rule?.nextDueDate ??
      DateTime.now().add(const Duration(days: 1));
  late bool _isActive = widget.rule?.isActive ?? true;
  bool _prefilled = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _prefill(FinanceSnapshot snapshot) {
    if (_prefilled) return;
    _prefilled = true;
    _accountId = widget.rule?.accountId ?? snapshot.accounts.firstOrNull?.id;
    _categoryId = widget.rule?.categoryId ??
        snapshot.categoriesOf(_kindFor(_type)).firstOrNull?.id;
  }

  CategoryKind _kindFor(TransactionType type) =>
      type == TransactionType.income ? CategoryKind.income : CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);

    return SafeArea(
      child: snapshotAsync.when(
        loading: () => const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator())),
        error: (error, _) => SizedBox(
            height: 200, child: Center(child: Text('$error'))),
        data: (snapshot) {
          _prefill(snapshot);
          final categories = snapshot.categoriesOf(_kindFor(_type));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.rule == null
                              ? 'Transaksi Berulang Baru'
                              : 'Edit Transaksi Berulang',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (widget.rule != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(financeControllerProvider)
                                .deleteRecurringRule(widget.rule!.id);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Keluar')),
                      ButtonSegment(
                          value: TransactionType.income, label: Text('Masuk')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (values) => setState(() {
                      _type = values.first;
                      _categoryId =
                          snapshot.categoriesOf(_kindFor(_type)).firstOrNull?.id;
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        labelText: 'Nama (mis. Netflix)'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  AmountField(controller: _amountController),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: categories.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(AppIcons.resolve(category.iconCodePoint),
                                  size: 18, color: Color(category.colorValue)),
                              const SizedBox(width: 10),
                              Text(category.name),
                            ],
                          ),
                        ),
                    ],
                    validator: (value) => value == null ? 'Pilih kategori' : null,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: snapshot.accounts.any((a) => a.id == _accountId)
                        ? _accountId
                        : null,
                    decoration: const InputDecoration(labelText: 'Akun'),
                    items: [
                      for (final account in snapshot.accounts)
                        DropdownMenuItem(
                            value: account.id, child: Text(account.name)),
                    ],
                    validator: (value) => value == null ? 'Pilih akun' : null,
                    onChanged: (value) => setState(() => _accountId = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: '$_intervalCount',
                          decoration:
                              const InputDecoration(labelText: 'Setiap'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() =>
                              _intervalCount = int.tryParse(value) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<RecurringInterval>(
                          initialValue: _intervalUnit,
                          decoration:
                              const InputDecoration(labelText: 'Interval'),
                          items: [
                            for (final unit in RecurringInterval.values)
                              DropdownMenuItem(
                                  value: unit, child: Text(unit.label)),
                          ],
                          onChanged: (value) => setState(
                              () => _intervalUnit = value ?? _intervalUnit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                        'Jatuh tempo berikutnya: ${Formatters.shortDate(_nextDueDate)}'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    title: const Text('Aktif'),
                    subtitle: const Text(
                        'Nonaktifkan untuk berhenti diingatkan sementara.'),
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _submit, child: const Text('Simpan')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Jatuh tempo berikutnya',
    );
    if (picked == null) return;
    setState(() => _nextDueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(financeControllerProvider);
    final amount = Formatters.parseAmount(_amountController.text);

    final existing = widget.rule;
    if (existing == null) {
      await controller.createRecurringRule(
        title: _titleController.text.trim(),
        type: _type,
        amount: amount,
        accountId: _accountId!,
        categoryId: _categoryId,
        intervalUnit: _intervalUnit,
        intervalCount: _intervalCount < 1 ? 1 : _intervalCount,
        nextDueDate: _nextDueDate,
      );
    } else {
      await controller.saveRecurringRule(existing.copyWith(
        title: _titleController.text.trim(),
        type: _type,
        amount: amount,
        accountId: _accountId!,
        categoryId: _categoryId,
        intervalUnit: _intervalUnit,
        intervalCount: _intervalCount < 1 ? 1 : _intervalCount,
        nextDueDate: _nextDueDate,
        isActive: _isActive,
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
