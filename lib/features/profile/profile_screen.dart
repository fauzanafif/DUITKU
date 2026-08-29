import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/widgets/section_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.settings;
    final snapshot = ref.watch(financeSnapshotProvider).valueOrNull;
    final currencyCode = settings.currencyCode;
    final name = settings.userName.isEmpty ? 'Pengguna DUITKU' : settings.userName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          SectionCard(
            child: Row(
              children: [
                _ProfilePhoto(
                  initial: name.characters.first.toUpperCase(),
                  photoBase64: settings.profilePhotoBase64,
                  onTap: () => _editPhoto(context, ref),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        'Total saldo '
                        '${Formatters.currency(snapshot?.totalBalance ?? 0, currencyCode: currencyCode)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Kelola'),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Akun',
            subtitle: '${snapshot?.accounts.length ?? 0} akun tersimpan',
            onTap: () => context.push('/accounts'),
          ),
          _MenuTile(
            icon: Icons.pie_chart_outline,
            title: 'Budget',
            subtitle: 'Batas pengeluaran per kategori',
            onTap: () => context.push('/budget'),
          ),
          _MenuTile(
            icon: Icons.flag_outlined,
            title: 'Target Keuangan',
            subtitle: 'Tabungan dan rencana besar',
            onTap: () => context.push('/savings'),
          ),
          _MenuTile(
            icon: Icons.credit_card_outlined,
            title: 'Cicilan & Utang',
            subtitle: 'Kartu kredit, paylater, cicilan barang',
            onTap: () => context.push('/debts'),
          ),
          _MenuTile(
            icon: Icons.autorenew,
            title: 'Transaksi Berulang',
            subtitle: 'Langganan dan tagihan rutin',
            onTap: () => context.push('/recurring'),
          ),
          _MenuTile(
            icon: Icons.category_outlined,
            title: 'Kategori',
            subtitle: '${snapshot?.categories.length ?? 0} kategori',
            onTap: () => context.push('/settings/categories'),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Aplikasi'),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            subtitle: 'Tema, pengingat, mata uang',
            onTap: () => context.push('/settings'),
          ),
          _MenuTile(
            icon: Icons.lock_outline,
            title: 'Keamanan',
            subtitle: settings.pinEnabled ? 'PIN aktif' : 'PIN belum diaktifkan',
            onTap: () => context.push('/settings/security'),
          ),
          _MenuTile(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            subtitle: 'Ekspor JSON/CSV, impor data',
            onTap: () => context.push('/settings/backup'),
          ),
          _MenuTile(
            icon: Icons.history,
            title: 'Log Aktivitas',
            subtitle: 'Riwayat perubahan data',
            onTap: () => context.push('/activity-log'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'DUITKU •  uangmu, capai tujuanmu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

Future<void> _editPhoto(BuildContext context, WidgetRef ref) async {
  final hasPhoto = ref.settings.profilePhotoBase64 != null;
  final choice = await showModalBottomSheet<_PhotoAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil Foto'),
            onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.camera),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus Foto'),
              onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return;

  final notifier = ref.read(settingsProvider.notifier);
  if (choice == _PhotoAction.remove) {
    await notifier.mutate((s) => s.copyWith(profilePhotoBase64: null));
    return;
  }

  try {
    final picked = await ImagePicker().pickImage(
      source: choice == _PhotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await notifier.mutate(
        (s) => s.copyWith(profilePhotoBase64: base64Encode(bytes)));
  } on Object catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $error')));
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.initial,
    required this.photoBase64,
    required this.onTap,
  });

  final String initial;
  final String? photoBase64;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: photoBase64 == null
                ? null
                : MemoryImage(base64Decode(photoBase64!)),
            child: photoBase64 != null
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 12, color: scheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
