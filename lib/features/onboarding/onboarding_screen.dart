import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/widgets/amount_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _slides = [
    (
      icon: Icons.edit_note,
      title: 'Catat setiap transaksi.',
      body: 'Pemasukan, pengeluaran, transfer, dan tarik cash dalam hitungan '
          'detik.',
    ),
    (
      icon: Icons.insights,
      title: 'Pantau kondisi keuanganmu.',
      body: 'Saldo tiap akun, laporan bulanan, dan komposisi pengeluaran.',
    ),
    (
      icon: Icons.flag,
      title: 'Capai target finansialmu.',
      body: 'Budget per kategori dan target tabungan yang terukur.',
    ),
  ];

  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountNameController = TextEditingController(text: 'BCA');
  final _balanceController = TextEditingController();

  int _page = 0;
  bool _showForm = false;
  AccountType _accountType = AccountType.bank;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: _showForm ? _buildForm(theme) : _buildSlides(theme),
      ),
    );
  }

  Widget _buildSlides(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slide.icon,
                          size: 56, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: FilledButton(
            onPressed: () {
              if (_page < _slides.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              } else {
                setState(() => _showForm = true);
              }
            },
            child: Text(
                _page < _slides.length - 1 ? 'Lanjut' : 'Mulai Sekarang'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DUITKU',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('Kelola uangmu, capai tujuanmu.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama kamu'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Mata uang',
                hintText: 'IDR (Rupiah)',
              ),
            ),
            const SizedBox(height: 24),
            Text('Akun pertama',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(labelText: 'Nama akun'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama akun wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AccountType>(
              initialValue: _accountType,
              decoration: const InputDecoration(labelText: 'Tipe akun'),
              items: [
                for (final type in AccountType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) =>
                  setState(() => _accountType = value ?? AccountType.bank),
            ),
            const SizedBox(height: 14),
            AmountField(controller: _balanceController, label: 'Saldo awal'),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final controller = ref.read(financeControllerProvider);
    await controller.createAccount(
      name: _accountNameController.text.trim(),
      type: _accountType,
      initialBalance: Formatters.parseAmount(_balanceController.text),
      iconCodePoint: AppDefaults.accountTypeIcons[_accountType]!.codePoint,
      colorValue: AppDefaults.palette.first.toARGB32(),
    );
    if (_accountType != AccountType.cash) {
      await controller.ensureCashAccount();
    }
    await ref.read(settingsProvider.notifier).mutate(
          (settings) => settings.copyWith(
            userName: _nameController.text.trim(),
            onboardingCompleted: true,
          ),
        );
    if (!mounted) return;
    context.go('/home');
  }
}
