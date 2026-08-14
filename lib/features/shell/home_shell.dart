import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/data/models/transaction.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: _BottomBar(navigationShell: navigationShell),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomAppBar(
      height: 74,
      color: theme.navigationBarTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Beranda',
            index: 0,
            shell: navigationShell,
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'Transaksi',
            index: 1,
            shell: navigationShell,
          ),
          const SizedBox(width: 64),
          _NavItem(
            icon: Icons.pie_chart_outline,
            activeIcon: Icons.pie_chart,
            label: 'Laporan',
            index: 2,
            shell: navigationShell,
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profil',
            index: 3,
            shell: navigationShell,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.shell,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = shell.currentIndex == index;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => shell.goBranch(index, initialLocation: selected),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      Widget action({
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required String location,
      }) {
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          onTap: () {
            Navigator.of(sheetContext).pop();
            GoRouter.of(context).push(location);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tambah Transaksi',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
              action(
                icon: Icons.south_west,
                color: AppColors.income,
                title: 'Pemasukan',
                subtitle: 'Uang masuk ke akunmu',
                location:
                    '/transactions/add?type=${TransactionType.income.name}',
              ),
              action(
                icon: Icons.north_east,
                color: AppColors.expense,
                title: 'Pengeluaran',
                subtitle: 'Uang keluar untuk belanja',
                location:
                    '/transactions/add?type=${TransactionType.expense.name}',
              ),
              action(
                icon: Icons.swap_horiz,
                color: AppColors.transfer,
                title: 'Transfer',
                subtitle: 'Pindah dana antar akun sendiri',
                location:
                    '/transactions/add?type=${TransactionType.transfer.name}',
              ),
              action(
                icon: Icons.atm,
                color: AppColors.brand,
                title: 'Tarik Cash',
                subtitle: 'Bank → Cash, bukan pengeluaran',
                location:
                    '/transactions/add?type=${TransactionType.transfer.name}&mode=withdraw',
              ),
            ],
          ),
        ),
      );
    },
  );
}
