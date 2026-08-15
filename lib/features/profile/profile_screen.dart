import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final name = settings.userName.isEmpty ? 'Pengguna DUITKU' : settings.userName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
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
                        '${Formatters.currency(snapshot?.totalBalance ?? 0)}',
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
          const SizedBox(height: 20),
          Center(
            child: Text(
              'DUITKU • Kelola uangmu, capai tujuanmu.',
              style: Theme.of(context).textTheme.bodySmall,
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
