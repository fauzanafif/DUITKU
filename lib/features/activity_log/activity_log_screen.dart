import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/theme/app_theme.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/data/models/activity_log_entry.dart';
import 'package:duitku/features/activity_log/log_filter.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    final filter = ref.watch(logFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _FilterSheet(),
            ),
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(error: error),
        data: (logs) {
          final filtered = filter.apply(logs);
          if (filtered.isEmpty) {
            return EmptyStateView(
              icon: Icons.history,
              title:
                  logs.isEmpty ? 'Belum ada aktivitas' : 'Tidak ada hasil',
              message: logs.isEmpty
                  ? 'Semua perubahan data akan tercatat otomatis di sini.'
                  : 'Coba ubah filter atau tekan Reset Filter.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _LogTile(entry: filtered[index]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final ActivityLogEntry entry;

  Color get _color {
    switch (entry.action) {
      case LogAction.create:
        return AppColors.income;
      case LogAction.update:
        return AppColors.warning;
      case LogAction.delete:
        return AppColors.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.action.name.toUpperCase(),
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.module.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${Formatters.shortDate(entry.timestamp)} '
                  '${Formatters.time(entry.timestamp)}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.entityName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (entry.detail != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(logFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(logFilterProvider);
    final notifier = ref.read(logFilterProvider.notifier);
    final hasRange = filter.dateFrom != null && filter.dateTo != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filter Aktivitas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      notifier.state = const LogFilter();
                    },
                    child: const Text('Reset Filter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau detail...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    notifier.update((s) => s.copyWith(query: value)),
              ),
              const SizedBox(height: 16),
              const Text('Tanggal',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: hasRange
                        ? DateTimeRange(
                            start: filter.dateFrom!, end: filter.dateTo!)
                        : null,
                    helpText: 'Pilih rentang tanggal',
                  );
                  if (picked == null) return;
                  notifier.update((s) => s.copyWith(
                        dateFrom: picked.start,
                        dateTo: picked.end,
                      ));
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  hasRange
                      ? '${Formatters.shortDate(filter.dateFrom!)} - '
                          '${Formatters.shortDate(filter.dateTo!)}'
                      : 'Semua tanggal',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Jenis Aksi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: filter.action == null,
                    onSelected: (_) =>
                        notifier.update((s) => s.copyWith(action: null)),
                  ),
                  for (final action in LogAction.values)
                    ChoiceChip(
                      label: Text(action.label),
                      selected: filter.action == action,
                      onSelected: (_) => notifier
                          .update((s) => s.copyWith(action: action)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Modul',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: filter.module == null,
                    onSelected: (_) =>
                        notifier.update((s) => s.copyWith(module: null)),
                  ),
                  for (final module in LogModule.values)
                    ChoiceChip(
                      label: Text(module.label),
                      selected: filter.module == module,
                      onSelected: (_) => notifier
                          .update((s) => s.copyWith(module: module)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terapkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
