import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/icon_color_picker.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Target Keuangan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Target Baru'),
      ),
      body: goalsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyStateView(
              icon: Icons.flag_outlined,
              title: 'Belum ada target',
              message: 'Buat target seperti Laptop, Dana Darurat, atau Liburan.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Buat Target'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              for (final goal in goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalCard(goal: goal),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {SavingGoal? goal}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _GoalEditor(goal: goal),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(goal.colorValue);
    final currencyCode = ref.settings.currencyCode;
    return SectionCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: _GoalEditor(goal: goal),
        ),
      ),
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
                child: Icon(
                  AppIcons.resolve(goal.iconCodePoint),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if (goal.targetDate != null)
                      Text('Target ${Formatters.shortDate(goal.targetDate!)}',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(Formatters.percent(goal.progress),
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${Formatters.currency(goal.currentAmount, currencyCode: currencyCode)} dari '
            '${Formatters.currency(goal.targetAmount, currencyCode: currencyCode)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  onPressed: () => _addContribution(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Setor'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  onPressed: goal.contributions.isEmpty
                      ? null
                      : () => _showContributions(context, ref),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Riwayat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addContribution(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Setor ke ${goal.name}'),
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
    await ref.read(financeControllerProvider).addContribution(
          goal,
          amount: amount,
          date: DateTime.now(),
        );
  }

  void _showContributions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Text('Riwayat ${goal.name}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final contribution in goal.contributions.reversed)
              ListTile(
                title: Text(Formatters.currency(contribution.amount, currencyCode: ref.settings.currencyCode)),
                subtitle: Text(Formatters.dateTime(contribution.date)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await ref
                        .read(financeControllerProvider)
                        .removeContribution(goal, contribution.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.goal});

  final SavingGoal? goal;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.goal?.name ?? '');
  late final TextEditingController _targetController = TextEditingController(
    text: widget.goal == null
        ? ''
        : Formatters.thousands(widget.goal!.targetAmount),
  );
  late DateTime? _targetDate = widget.goal?.targetDate;
  late int _icon = widget.goal?.iconCodePoint ?? Icons.savings.codePoint;
  late int _color =
      widget.goal?.colorValue ?? AppDefaults.palette.first.toARGB32();

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.goal == null ? 'Target Baru' : 'Edit Target',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.goal != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref
                            .read(financeControllerProvider)
                            .deleteSavingGoal(widget.goal!.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama target'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama target wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              AmountField(controller: _targetController, label: 'Target dana'),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _targetDate == null
                      ? 'Tanggal target (opsional)'
                      : Formatters.fullDate(_targetDate!),
                ),
              ),
              const SizedBox(height: 16),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(financeControllerProvider);
    final target = Formatters.parseAmount(_targetController.text);
    final existing = widget.goal;
    if (existing == null) {
      await controller.createSavingGoal(
        name: _nameController.text.trim(),
        targetAmount: target,
        colorValue: _color,
        iconCodePoint: _icon,
        targetDate: _targetDate,
      );
    } else {
      await controller.saveSavingGoal(existing.copyWith(
        name: _nameController.text.trim(),
        targetAmount: target,
        colorValue: _color,
        iconCodePoint: _icon,
        targetDate: _targetDate,
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
