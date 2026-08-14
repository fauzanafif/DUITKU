import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/finance/transaction_validator.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/data/repositories/transaction_repository.dart';
import 'package:duitku/widgets/amount_field.dart';
import 'package:duitku/widgets/state_views.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.transactionId,
    this.withdrawCashMode = false,
  });

  final TransactionType initialType;
  final String? transactionId;
  final bool withdrawCashMode;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type = widget.initialType;
  DateTime _dateTime = DateTime.now();
  String? _categoryId;
  String? _accountId;
  String? _destinationAccountId;
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _prefill(FinanceSnapshot snapshot) {
    if (_prefilled) return;
    _prefilled = true;

    final editing = widget.transactionId == null
        ? null
        : snapshot.transactions
            .where((tx) => tx.id == widget.transactionId)
            .firstOrNull;

    if (editing != null) {
      _type = editing.type;
      _amountController.text = Formatters.thousands(editing.amount);
      _titleController.text = editing.title;
      _noteController.text = editing.note ?? '';
      _dateTime = editing.transactionDateTime;
      _categoryId = editing.categoryId;
      _accountId = editing.accountId;
      _destinationAccountId = editing.destinationAccountId;
      return;
    }

    if (widget.withdrawCashMode) {
      _type = TransactionType.transfer;
      _titleController.text = 'Tarik Cash';
      final cash = snapshot.cashAccount;
      _destinationAccountId = cash?.id;
      _accountId = snapshot.accounts
          .where((a) => a.type != AccountType.cash)
          .firstOrNull
          ?.id;
      return;
    }

    _accountId = snapshot.accounts.firstOrNull?.id;
    _destinationAccountId = snapshot.accounts.length > 1
        ? snapshot.accounts
            .where((a) => a.id != _accountId)
            .firstOrNull
            ?.id
        : null;
    _categoryId = _defaultCategoryId(snapshot);
  }

  String? _defaultCategoryId(FinanceSnapshot snapshot) {
    if (_type == TransactionType.transfer) return null;
    final kind = _type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    return snapshot.categoriesOf(kind).firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaksi' : _screenTitle()),
      ),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) {
          _prefill(snapshot);
          if (snapshot.accounts.isEmpty) {
            return const EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada akun',
              message: 'Tambahkan minimal satu akun sebelum mencatat transaksi.',
            );
          }
          return _buildForm(snapshot);
        },
      ),
    );
  }

  String _screenTitle() {
    if (widget.withdrawCashMode) return 'Tarik Cash';
    return 'Tambah ${_type.label}';
  }

  Widget _buildForm(FinanceSnapshot snapshot) {
    final isTransfer = _type == TransactionType.transfer;
    final categories = snapshot.categoriesOf(
      _type == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense,
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (!widget.withdrawCashMode) ...[
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Masuk'),
                  icon: Icon(Icons.south_west, size: 18),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Keluar'),
                  icon: Icon(Icons.north_east, size: 18),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz, size: 18),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() {
                  _type = values.first;
                  _categoryId = _defaultCategoryId(snapshot);
                  if (_type == TransactionType.transfer) {
                    _destinationAccountId ??= snapshot.accounts
                        .where((a) => a.id != _accountId)
                        .firstOrNull
                        ?.id;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],
          AmountField(controller: _amountController, autofocus: !_isEditing),
          const SizedBox(height: 16),
          if (!isTransfer) ...[
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
                        Icon(
                          AppIcons.resolve(category.iconCodePoint),
                          size: 18,
                          color: Color(category.colorValue),
                        ),
                        const SizedBox(width: 10),
                        Text(category.name),
                      ],
                    ),
                  ),
              ],
              validator: (value) => value == null ? 'Pilih kategori' : null,
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 16),
          ],
          _accountDropdown(
            label: isTransfer ? 'Dari akun' : 'Akun',
            value: _accountId,
            accounts: snapshot.accounts,
            onChanged: (value) => setState(() => _accountId = value),
          ),
          if (isTransfer) ...[
            const SizedBox(height: 16),
            _accountDropdown(
              label: 'Ke akun',
              value: _destinationAccountId,
              accounts: snapshot.accounts,
              onChanged: (value) =>
                  setState(() => _destinationAccountId = value),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.event,
                  label: 'Tanggal',
                  value: Formatters.fullDate(_dateTime),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule,
                  label: 'Waktu',
                  value: Formatters.time(_dateTime),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Judul',
              hintText: isTransfer ? 'Transfer antar akun' : 'Opsional',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Catatan'),
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : () => _submit(snapshot),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required String? value,
    required List<Account> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: accounts.any((a) => a.id == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Row(
              children: [
                Icon(
                  AppIcons.resolve(account.iconCodePoint),
                  size: 18,
                  color: Color(account.colorValue),
                ),
                const SizedBox(width: 10),
                Text(account.name),
              ],
            ),
          ),
      ],
      validator: (value) => value == null ? 'Pilih akun' : null,
      onChanged: onChanged,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Tanggal transaksi',
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      helpText: 'Waktu transaksi',
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit(FinanceSnapshot snapshot) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = Formatters.parseAmount(_amountController.text);
    final category = snapshot.categoriesById[_categoryId];

    var title = _titleController.text.trim();
    if (title.isEmpty) {
      title = _type == TransactionType.transfer
          ? (widget.withdrawCashMode ? 'Tarik Cash' : 'Transfer')
          : (category?.name ?? _type.label);
    }

    final draft = TransactionDraft(
      type: _type,
      title: title,
      amount: amount,
      accountId: _accountId ?? '',
      destinationAccountId: _destinationAccountId,
      categoryId: _type == TransactionType.transfer ? null : _categoryId,
      transactionDateTime: _dateTime,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    setState(() => _saving = true);
    final controller = ref.read(financeControllerProvider);
    try {
      if (_isEditing) {
        await controller.updateTransaction(widget.transactionId!, draft);
      } else {
        await controller.addTransaction(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ValidationFailure catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
