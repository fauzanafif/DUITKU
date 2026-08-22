import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/icon_color_picker.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);
    final currencyCode = ref.settings.currencyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Akun Baru'),
      ),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) {
          if (snapshot.accounts.isEmpty) {
            return EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada akun',
              message:
                  'Tambahkan bank, e-wallet atau cash untuk mulai mencatat.',
              action: FilledButton.icon(
                onPressed: () => showAccountEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Akun'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      Formatters.currency(snapshot.totalBalance, currencyCode: currencyCode),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final account in snapshot.accounts) ...[
                _AccountCard(
                  account: account,
                  balance: snapshot.balanceOf(account.id),
                  currencyCode: currencyCode,
                  onTap: () => account.type == AccountType.allowance
                      ? context.push('/accounts/allowance/${account.id}')
                      : showAccountEditor(context, ref, account: account),
                  onDelete: () => _confirmDelete(context, ref, account),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus ${account.name}?'),
        content: const Text(
          'Akun hanya bisa dihapus jika belum pernah dipakai transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(financeControllerProvider).deleteAccount(account.id);
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balance,
    required this.currencyCode,
    required this.onTap,
    required this.onDelete,
  });

  final Account account;
  final double balance;
  final String currencyCode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              AppIcons.resolve(account.iconCodePoint),
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  account.type.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(balance, currencyCode: currencyCode),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                'Saldo awal ${Formatters.currency(account.initialBalance, currencyCode: currencyCode)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

Future<void> showAccountEditor(
  BuildContext context,
  WidgetRef ref, {
  Account? account,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AccountEditor(account: account),
    ),
  );
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({this.account});

  final Account? account;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.account?.name ?? '');
  late final TextEditingController _balanceController = TextEditingController(
    text: widget.account == null
        ? ''
        : Formatters.thousands(widget.account!.initialBalance),
  );

  late AccountType _type = widget.account?.type ?? AccountType.bank;
  late int _icon = widget.account?.iconCodePoint ??
      AppDefaults.accountTypeIcons[AccountType.bank]!.codePoint;
  late int _color =
      widget.account?.colorValue ?? AppDefaults.palette.first.toARGB32();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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
              Text(
                widget.account == null ? 'Akun Baru' : 'Edit Akun',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama akun',
                  hintText: 'BCA, Mandiri, Cash, GoPay...',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama akun wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AccountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe akun'),
                items: [
                  for (final type in AccountType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    _icon = AppDefaults.accountTypeIcons[value]!.codePoint;
                  });
                },
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _balanceController,
                label: 'Saldo awal',
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
              FilledButton(
                onPressed: _submit,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(financeControllerProvider);
    final balance = Formatters.parseAmount(_balanceController.text);
    final existing = widget.account;

    if (existing == null) {
      await controller.createAccount(
        name: _nameController.text,
        type: _type,
        initialBalance: balance,
        iconCodePoint: _icon,
        colorValue: _color,
      );
    } else {
      await controller.saveAccount(existing.copyWith(
        name: _nameController.text.trim(),
        type: _type,
        initialBalance: balance,
        iconCodePoint: _icon,
        colorValue: _color,
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
