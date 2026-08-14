import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/finance_snapshot.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/transaction.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';
import 'package:duitku/widgets/transaction_tile.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(financeSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.push('/transactions/edit/$transactionId'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (snapshot) {
          final tx = snapshot.transactions
              .firstWhereOrNull((item) => item.id == transactionId);
          if (tx == null) {
            return const EmptyStateView(
              icon: Icons.search_off,
              title: 'Transaksi tidak ditemukan',
            );
          }
          final color = transactionColor(tx.type);
          final source = snapshot.accountsById[tx.accountId];
          final destination = snapshot.accountsById[tx.destinationAccountId];
          final category = snapshot.categoriesById[tx.categoryId];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          Icon(transactionIcon(tx.type), color: color, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      signedAmountLabel(tx),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(tx.type.label,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  children: [
                    _DetailRow(label: 'Judul', value: tx.title),
                    _DetailRow(
                      label: 'Tanggal transaksi',
                      value: Formatters.dateTime(tx.transactionDateTime),
                    ),
                    if (tx.isTransfer) ...[
                      _DetailRow(
                          label: 'Dari akun', value: source?.name ?? '-'),
                      _DetailRow(
                          label: 'Ke akun', value: destination?.name ?? '-'),
                    ] else ...[
                      _DetailRow(label: 'Akun', value: source?.name ?? '-'),
                      _DetailRow(
                          label: 'Kategori', value: category?.name ?? '-'),
                    ],
                    if (tx.note != null && tx.note!.isNotEmpty)
                      _DetailRow(label: 'Catatan', value: tx.note!),
                    _DetailRow(
                      label: 'Dicatat pada',
                      value: Formatters.dateTime(tx.createdAt),
                    ),
                    if (tx.updatedAt.difference(tx.createdAt).inSeconds > 1)
                      _DetailRow(
                        label: 'Diubah pada',
                        value: Formatters.dateTime(tx.updatedAt),
                      ),
                  ],
                ),
              ),
              if (tx.isTransfer) ...[
                const SizedBox(height: 16),
                SectionCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transfer antar akun tidak dihitung sebagai '
                          'pemasukan maupun pengeluaran, dan tidak memengaruhi '
                          'budget.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text(
          'Saldo akun akan dikembalikan seperti sebelum transaksi ini dibuat.',
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
    await ref.read(financeControllerProvider).deleteTransaction(transactionId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
