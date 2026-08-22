import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/icon_color_picker.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

/// The next occurrence of [dueDay] from now, at 09:00 local time. Clamped to
/// the last day of a shorter month (e.g. dueDay 31 in February).
DateTime nextDueDateFor(int dueDay) {
  DateTime forMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dueDay.clamp(1, lastDay), 9);
  }

  final now = DateTime.now();
  var candidate = forMonth(now.year, now.month);
  if (!candidate.isAfter(now)) {
    candidate = forMonth(now.year, now.month + 1);
  }
  return candidate;
}

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cicilan & Utang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDebtEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: debtsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (debts) {
          if (debts.isEmpty) {
            return EmptyStateView(
              icon: Icons.credit_card_outlined,
              title: 'Belum ada cicilan',
              message: 'Catat cicilan, kartu kredit, atau paylater biar '
                  'nggak ada yang kelewat bayar.',
              action: FilledButton.icon(
                onPressed: () => openDebtEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Cicilan'),
              ),
            );
          }

          final active = debts.where((d) => !d.isSettled).toList()
            ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
          final settled = debts.where((d) => d.isSettled).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              for (final debt in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtCard(debt: debt),
                ),
              if (settled.isNotEmpty) ...[
                const SectionHeader(title: 'Lunas'),
                for (final debt in settled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(debt: debt),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> openDebtEditor(BuildContext context, {Debt? debt}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _DebtEditor(debt: debt),
    ),
  );
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(debt.colorValue);
    final currencyCode = ref.settings.currencyCode;
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;
    final hasHistory =
        snapshot?.transactions.any((tx) => tx.debtId == debt.id) ?? false;

    return SectionCard(
      onTap: () => openDebtEditor(context, debt: debt),
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
                child: Icon(AppIcons.resolve(debt.iconCodePoint), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${debt.type.label} • Jatuh tempo tgl ${debt.dueDay}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (debt.isSettled)
                const Icon(Icons.check_circle, color: AppColors.income)
              else if (debt.totalAmount != null)
                Text(
                  Formatters.percent(debt.progress),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          if (debt.totalAmount != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            debt.totalAmount == null
                ? 'Sisa ${Formatters.currency(debt.remainingAmount, currencyCode: currencyCode)}'
                : 'Sisa ${Formatters.currency(debt.remainingAmount, currencyCode: currencyCode)} '
                    'dari ${Formatters.currency(debt.totalAmount!, currencyCode: currencyCode)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!debt.isSettled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40)),
                    onPressed: () => _pay(context, ref),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Bayar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40)),
                    onPressed: !hasHistory
                        ? null
                        : () => _showHistory(context, ref, snapshot!),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Riwayat'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final snapshot = ref.read(financeSnapshotProvider).valueOrNull;
    if (snapshot == null || snapshot.accounts.isEmpty) return;

    final amountController = TextEditingController(
      text: debt.installmentAmount == null
          ? ''
          : Formatters.thousands(debt.installmentAmount!),
    );
    var accountId = debt.accountId ?? snapshot.accounts.first.id;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Bayar ${debt.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmountField(controller: amountController, autofocus: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(labelText: 'Dari akun'),
                  items: [
                    for (final account in snapshot.accounts)
                      DropdownMenuItem(
                          value: account.id, child: Text(account.name)),
                  ],
                  onChanged: (value) =>
                      setState(() => accountId = value ?? accountId),
                ),
              ],
            ),
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
                    .pop(Formatters.parseAmount(amountController.text));
              },
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    if (result == null) return;

    await ref.read(financeControllerProvider).payDebt(
          debt,
          amount: result,
          accountId: accountId,
          date: DateTime.now(),
        );
  }

  void _showHistory(
    BuildContext context,
    WidgetRef ref,
    FinanceSnapshot snapshot,
  ) {
    final payments = snapshot.transactions
        .where((tx) => tx.debtId == debt.id)
        .toList()
      ..sort((a, b) => b.transactionDateTime.compareTo(a.transactionDateTime));
    final currencyCode = ref.settings.currencyCode;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Text('Riwayat ${debt.name}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final payment in payments)
              ListTile(
                title: Text(Formatters.currency(payment.amount,
                    currencyCode: currencyCode)),
                subtitle:
                    Text(Formatters.dateTime(payment.transactionDateTime)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtEditor extends ConsumerStatefulWidget {
  const _DebtEditor({this.debt});

  final Debt? debt;

  @override
  ConsumerState<_DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends ConsumerState<_DebtEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.debt?.name ?? '');
  late final TextEditingController _totalController = TextEditingController(
    text: widget.debt?.totalAmount == null
        ? ''
        : Formatters.thousands(widget.debt!.totalAmount!),
  );
  late final TextEditingController _remainingController =
      TextEditingController(
    text: widget.debt == null
        ? ''
        : Formatters.thousands(widget.debt!.remainingAmount),
  );
  late final TextEditingController _installmentController =
      TextEditingController(
    text: widget.debt?.installmentAmount == null
        ? ''
        : Formatters.thousands(widget.debt!.installmentAmount!),
  );

  late DebtType _type = widget.debt?.type ?? DebtType.installment;
  late int _dueDay = widget.debt?.dueDay ?? 1;
  late String? _accountId = widget.debt?.accountId;
  late int _icon = widget.debt?.iconCodePoint ?? Icons.credit_card.codePoint;
  late int _color =
      widget.debt?.colorValue ?? AppDefaults.palette.first.toARGB32();
  late bool _reminderEnabled = widget.debt?.reminderEnabled ?? false;

  @override
  void dispose() {
    _nameController.dispose();
    _totalController.dispose();
    _remainingController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;
    final accounts = snapshot?.accounts ?? const [];

    return SafeArea(
      child: SingleChildScrollView(
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
                      widget.debt == null ? 'Cicilan Baru' : 'Edit Cicilan',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.debt != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final controller = ref.read(financeControllerProvider);
                        await controller.deleteDebt(widget.debt!.id);
                        await ref
                            .read(notificationServiceProvider)
                            .cancelReminderFor('debt', widget.debt!.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nama (mis. Kartu BCA)'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              SegmentedButton<DebtType>(
                segments: [
                  for (final type in DebtType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_type},
                onSelectionChanged: (values) =>
                    setState(() => _type = values.first),
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _remainingController,
                label: 'Sisa tagihan saat ini',
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _totalController,
                label: 'Total pinjaman (opsional)',
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _installmentController,
                label: 'Cicilan per bulan (opsional)',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration:
                    const InputDecoration(labelText: 'Tanggal jatuh tempo'),
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('Tanggal $day')),
                ],
                onChanged: (value) =>
                    setState(() => _dueDay = value ?? _dueDay),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: accounts.any((a) => a.id == _accountId)
                    ? _accountId
                    : null,
                decoration: const InputDecoration(
                    labelText: 'Akun pembayaran (opsional)'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Tidak ditentukan')),
                  for (final account in accounts)
                    DropdownMenuItem(
                        value: account.id, child: Text(account.name)),
                ],
                onChanged: (value) => setState(() => _accountId = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _reminderEnabled,
                title: const Text('Ingatkan sebelum jatuh tempo'),
                subtitle: const Text(
                    'Notifikasi sekali menjelang tanggal jatuh tempo bulan ini.'),
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),
              const SizedBox(height: 8),
              const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              IconPickerRow(
                selected: _icon,
                onChanged: (value) => setState(() => _icon = value),
              ),
              const SizedBox(height: 16),
              const Text('Warna',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ColorPickerRow(
                selected: _color,
                onChanged: (value) => setState(() => _color = value),
              ),
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
    final notifications = ref.read(notificationServiceProvider);
    final remaining = Formatters.parseAmount(_remainingController.text);
    final total = _totalController.text.trim().isEmpty
        ? null
        : Formatters.parseAmount(_totalController.text);
    final installment = _installmentController.text.trim().isEmpty
        ? null
        : Formatters.parseAmount(_installmentController.text);

    final existing = widget.debt;
    String debtId;
    if (existing == null) {
      final created = await controller.createDebt(
        name: _nameController.text.trim(),
        type: _type,
        remainingAmount: remaining,
        dueDay: _dueDay,
        colorValue: _color,
        iconCodePoint: _icon,
        totalAmount: total,
        installmentAmount: installment,
        accountId: _accountId,
        reminderEnabled: _reminderEnabled,
      );
      debtId = created.id;
    } else {
      await controller.saveDebt(existing.copyWith(
        name: _nameController.text.trim(),
        type: _type,
        remainingAmount: remaining,
        dueDay: _dueDay,
        colorValue: _color,
        iconCodePoint: _icon,
        totalAmount: total,
        installmentAmount: installment,
        accountId: _accountId,
        reminderEnabled: _reminderEnabled,
        isSettled: remaining <= 0,
      ));
      debtId = existing.id;
    }

    if (_reminderEnabled) {
      await notifications.requestPermission();
      await notifications.scheduleOneTimeReminder(
        namespace: 'debt',
        key: debtId,
        title: 'DUITKU',
        body: '${_nameController.text.trim()} jatuh tempo tanggal $_dueDay.',
        dateTime: nextDueDateFor(_dueDay),
      );
    } else {
      await notifications.cancelReminderFor('debt', debtId);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
