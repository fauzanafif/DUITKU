import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/services/backup_service.dart';
import 'package:duitku/core/utils/json_utils.dart';
import 'package:duitku/widgets/section_card.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  List<File> _files = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFiles());
  }

  Future<void> _loadFiles() async {
    try {
      final files = await ref.read(backupServiceProvider).listBackupFiles();
      if (!mounted) return;
      setState(() => _files = files);
    } on Object catch (error) {
      _notify('Gagal membaca folder backup: $error');
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on BackupFormatException catch (error) {
      _notify(error.message);
    } on Object catch (error) {
      _notify('Terjadi kesalahan: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(backupServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader(
              title: 'Ekspor',
              subtitle: 'Simpan salinan data ke penyimpanan perangkat.',
            ),
            SectionCard(
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => _run(() async {
                      final file = await service.exportJson();
                      await _loadFiles();
                      _notify('Backup JSON tersimpan: ${file.path}');
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path)],
                          text: 'Backup DUITKU',
                        ),
                      );
                    }),
                    icon: const Icon(Icons.download),
                    label: const Text('Export JSON'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _run(() async {
                      final file = await service.exportCsv();
                      _notify('CSV tersimpan: ${file.path}');
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path)],
                          text: 'Transaksi DUITKU',
                        ),
                      );
                    }),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Restore',
              subtitle: 'Pulihkan data dari file backup JSON.',
            ),
            if (_files.isEmpty)
              const SectionCard(
                child: Text(
                  'Belum ada file backup. Buat backup JSON terlebih dahulu, '
                  'atau salin file backup ke folder duitku-backup.',
                ),
              )
            else
              for (final file in _files)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(file.uri.pathSegments.last),
                      subtitle: Text(
                        '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: const Icon(Icons.restore),
                      onTap: () => _restore(file),
                    ),
                  ),
                ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _restore(File file) async {
    final service = ref.read(backupServiceProvider);
    await _run(() async {
      final payload = service.parse(await file.readAsString());
      if (!mounted) return;
      final mode = await showDialog<RestoreMode>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore data?'),
          content: Text(
            '${payload.totalRecords} data akan dipulihkan.\n\n'
            'Ganti: hapus seluruh data saat ini lalu pakai isi backup.\n'
            'Gabung: data lama dipertahankan, id yang sama dilewati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(RestoreMode.merge),
              child: const Text('Gabung'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(RestoreMode.replace),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
      if (mode == null) return;
      await service.restore(payload, mode);
      ref.invalidate(accountsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(savingGoalsProvider);
      _notify('Data berhasil dipulihkan.');
    });
  }
}
