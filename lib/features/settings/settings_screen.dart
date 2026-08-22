import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.settings;
    final notifier = ref.read(settingsProvider.notifier);
    final expenseCategories =
        ref.watch(financeSnapshotProvider).valueOrNull?.categoriesOf(
                CategoryKind.expense) ??
            const [];
    final currencyOptions = const [
      ('IDR', 'Rupiah Indonesia'),
      ('USD', 'US Dollar'),
      ('EUR', 'Euro'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const SectionHeader(title: 'Tampilan'),
              SectionCard(
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    for (final mode in ThemeMode.values)
                      ButtonSegment(value: mode, label: Text(_themeLabel(mode))),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => notifier
                      .mutate((s) => s.copyWith(themeMode: selection.first)),
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Profil'),
              SectionCard(
                child: TextFormField(
                  initialValue: settings.userName,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (value) =>
                      notifier.mutate((s) => s.copyWith(userName: value.trim())),
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Keuangan'),
              SectionCard(
                child: DropdownButtonFormField<String>(
                  initialValue: settings.currencyCode,
                  decoration: const InputDecoration(labelText: 'Mata uang'),
                  isExpanded: true,
                  items: [
                    for (final option in currencyOptions)
                      DropdownMenuItem(
                        value: option.$1,
                        child: Text('${option.$1} (${option.$2})'),
                      ),
                  ],
                  onChanged: (value) => notifier
                      .mutate((s) => s.copyWith(currencyCode: value ?? 'IDR')),
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Alokasi Gaji Otomatis',
                subtitle: 'Tanggal gajian juga menentukan siklus "bulan" di '
                    'Dashboard, Laporan, dan Budget.',
              ),
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: const Text('Tanggal gajian'),
                      trailing: DropdownButton<int>(
                        value: settings.payday,
                        items: [
                          for (var day = 1; day <= 31; day++)
                            DropdownMenuItem(value: day, child: Text('$day')),
                        ],
                        onChanged: (value) => notifier
                            .mutate((s) => s.copyWith(payday: value ?? 1)),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: settings.allocationEnabled,
                      title: const Text('Aktifkan alokasi otomatis'),
                      subtitle: const Text(
                          'Setiap catat pemasukan, ditawari pecah jadi budget '
                          '50/30/20 (bisa diubah).'),
                      onChanged: (value) => notifier
                          .mutate((s) => s.copyWith(allocationEnabled: value)),
                    ),
                    if (settings.allocationEnabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(
                                    'needs-${settings.allocationNeedsPercent}'),
                                initialValue: settings.allocationNeedsPercent
                                    .toStringAsFixed(0),
                                decoration: const InputDecoration(
                                    labelText: 'Kebutuhan %'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (value) => notifier.mutate(
                                    (s) => s.copyWith(
                                        allocationNeedsPercent:
                                            double.tryParse(value) ??
                                                s.allocationNeedsPercent)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(
                                    'wants-${settings.allocationWantsPercent}'),
                                initialValue: settings.allocationWantsPercent
                                    .toStringAsFixed(0),
                                decoration: const InputDecoration(
                                    labelText: 'Keinginan %'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (value) => notifier.mutate(
                                    (s) => s.copyWith(
                                        allocationWantsPercent:
                                            double.tryParse(value) ??
                                                s.allocationWantsPercent)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(
                                    'savings-${settings.allocationSavingsPercent}'),
                                initialValue: settings
                                    .allocationSavingsPercent
                                    .toStringAsFixed(0),
                                decoration: const InputDecoration(
                                    labelText: 'Tabungan %'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (value) => notifier.mutate(
                                    (s) => s.copyWith(
                                        allocationSavingsPercent:
                                            double.tryParse(value) ??
                                                s.allocationSavingsPercent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AllocationCategoryPicker(
                        label: 'Kategori Kebutuhan',
                        categories: expenseCategories,
                        value: settings.allocationNeedsCategoryId,
                        onChanged: (value) => notifier.mutate((s) =>
                            s.copyWith(allocationNeedsCategoryId: value)),
                      ),
                      const SizedBox(height: 8),
                      _AllocationCategoryPicker(
                        label: 'Kategori Keinginan',
                        categories: expenseCategories,
                        value: settings.allocationWantsCategoryId,
                        onChanged: (value) => notifier.mutate((s) =>
                            s.copyWith(allocationWantsCategoryId: value)),
                      ),
                      const SizedBox(height: 8),
                      _AllocationCategoryPicker(
                        label: 'Kategori Tabungan',
                        categories: expenseCategories,
                        value: settings.allocationSavingsCategoryId,
                        onChanged: (value) => notifier.mutate((s) =>
                            s.copyWith(allocationSavingsCategoryId: value)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Transaksi'),
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SwitchListTile(
                  value: settings.allowNegativeBalance,
                  title: const Text('Izinkan saldo minus'),
                  subtitle: const Text(
                      'Nonaktif: transaksi ditolak jika saldo tidak cukup.'),
                  onChanged: (value) => notifier
                      .mutate((s) => s.copyWith(allowNegativeBalance: value)),
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Pengingat'),
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.reminderEnabled,
                      title: const Text('Pengingat harian'),
                      subtitle:
                          const Text('Sudah mencatat pengeluaran hari ini?'),
                      onChanged: (value) async {
                        final service = ref.read(notificationServiceProvider);
                        if (value) {
                          await service.requestPermission();
                          await service.scheduleDailyReminder(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          );
                        } else {
                          await service.cancelReminder();
                        }
                        await notifier
                            .mutate((s) => s.copyWith(reminderEnabled: value));
                      },
                    ),
                    ListTile(
                      enabled: settings.reminderEnabled,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Waktu pengingat'),
                      trailing: Text(
                        '${settings.reminderHour.toString().padLeft(2, '0')}:'
                        '${settings.reminderMinute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: !settings.reminderEnabled
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.reminderHour,
                                  minute: settings.reminderMinute,
                                ),
                              );
                              if (picked == null) return;
                              await ref
                                  .read(notificationServiceProvider)
                                  .scheduleDailyReminder(
                                    hour: picked.hour,
                                    minute: picked.minute,
                                  );
                              await notifier.mutate((s) => s.copyWith(
                                    reminderHour: picked.hour,
                                    reminderMinute: picked.minute,
                                  ));
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Lainnya'),
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.credit_card_outlined),
                      title: const Text('Cicilan & Utang'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/debts'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.autorenew),
                      title: const Text('Transaksi Berulang'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/recurring'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Kategori'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/categories'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Keamanan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/security'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup & Restore'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/backup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Ikuti sistem',
        ThemeMode.light => 'Terang',
        ThemeMode.dark => 'Gelap',
      };
}

class _AllocationCategoryPicker extends StatelessWidget {
  const _AllocationCategoryPicker({
    required this.label,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: categories.any((c) => c.id == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final category in categories)
          DropdownMenuItem(value: category.id, child: Text(category.name)),
      ],
      onChanged: onChanged,
    );
  }
}
