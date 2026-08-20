import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/data/models/transaction.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showAddTransactionSheet(context),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: theme.navigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        height: 80,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
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
            const SizedBox(width: 72),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () => shell.goBranch(index, initialLocation: selected),
          splashColor: scheme.primary.withValues(alpha: 0.1),
          highlightColor: scheme.primary.withValues(alpha: 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(selected ? 8 : 0),
                decoration: BoxDecoration(
                  color: selected 
                      ? scheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? activeIcon : icon, 
                  color: color, 
                  size: selected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(context);
      
      Widget action({
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required String location,
      }) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Material(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                GoRouter.of(context).push(location);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Tambah Transaksi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
        ),
      );
    },
  );
}
