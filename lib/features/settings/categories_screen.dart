import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/utils/app_icons.dart';
import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/core/providers/finance_controller.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/widgets/icon_color_picker.dart';
import 'package:duitku/widgets/section_card.dart';
import 'package:duitku/widgets/state_views.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategori'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')],
          ),
        ),
        floatingActionButton: Builder(
          builder: (innerContext) => FloatingActionButton.extended(
            onPressed: () {
              final index = DefaultTabController.of(innerContext).index;
              _openEditor(
                context,
                kind: index == 0 ? CategoryKind.expense : CategoryKind.income,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Kategori'),
          ),
        ),
        body: categoriesAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorStateView(error: error),
          data: (categories) => TabBarView(
            children: [
              _CategoryList(
                categories: categories
                    .where((c) => c.kind == CategoryKind.expense)
                    .toList(),
                onEdit: (category) => _openEditor(context,
                    kind: category.kind, category: category),
                onDelete: (category) =>
                    _confirmDelete(context, ref, category, categories),
              ),
              _CategoryList(
                categories: categories
                    .where((c) => c.kind == CategoryKind.income)
                    .toList(),
                onEdit: (category) => _openEditor(context,
                    kind: category.kind, category: category),
                onDelete: (category) =>
                    _confirmDelete(context, ref, category, categories),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    required CategoryKind kind,
    Category? category,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _CategoryEditor(kind: kind, category: category),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
    List<Category> all,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus kategori "${category.name}"?'),
        content: const Text(
          'Transaksi lama dengan kategori ini tidak akan terhapus.',
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

    final controller = ref.read(financeControllerProvider);
    try {
      await controller.deleteCategory(category.id);
      return;
    } on StateError catch (error) {
      if (!context.mounted) return;
      final replacements =
          all.where((c) => c.kind == category.kind && c.id != category.id);
      if (replacements.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
      final replacementId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text('Pindahkan transaksi "${category.name}" ke:'),
          children: [
            for (final replacement in replacements)
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(replacement.id),
                child: Text(replacement.name),
              ),
          ],
        ),
      );
      if (replacementId == null) return;
      await controller.deleteCategory(category.id, reassignTo: replacementId);
    }
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> categories;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaults = categories.where((c) => c.isDefault).toList();
    final custom = categories.where((c) => !c.isDefault).toList();

    if (defaults.isEmpty && custom.isEmpty) {
      return const EmptyStateView(
        icon: Icons.category_outlined,
        title: 'Belum ada kategori',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        if (defaults.isNotEmpty) ...[
          const SectionHeader(
            title: 'Kategori Bawaan',
            subtitle: 'Selalu tersedia • tidak bisa diubah atau dihapus',
          ),
          for (final category in defaults)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryTile(category: category),
            ),
          const SizedBox(height: 16),
        ],
        const SectionHeader(
          title: 'Kategori Saya',
          subtitle: 'Kategori yang kamu buat sendiri',
        ),
        if (custom.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              'Belum ada. Tekan tombol + untuk membuat kategori sendiri.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          for (final category in custom)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryTile(
                category: category,
                onEdit: () => onEdit(category),
                onDelete: () => onDelete(category),
              ),
            ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.onEdit, this.onDelete});

  final Category category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onEdit,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              AppIcons.resolve(category.iconCodePoint),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (category.isDefault) ...[
                  const SizedBox(width: 8),
                  const _DefaultBadge(),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.lock_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Bawaan',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.kind, this.category});

  final CategoryKind kind;
  final Category? category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.category?.name ?? '');
  late int _icon = widget.category?.iconCodePoint ?? Icons.more_horiz.codePoint;
  late int _color =
      widget.category?.colorValue ?? AppDefaults.palette.first.toARGB32();
  late CategoryKind _kind = widget.category?.kind ?? widget.kind;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.category == null ? 'Kategori Baru' : 'Edit Kategori',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama kategori wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              SegmentedButton<CategoryKind>(
                segments: [
                  for (final kind in CategoryKind.values)
                    ButtonSegment(value: kind, label: Text(kind.label)),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) =>
                    setState(() => _kind = selection.first),
              ),
              const SizedBox(height: 16),
              const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              IconPickerRow(
                selected: _icon,
                onChanged: (value) => setState(() => _icon = value),
              ),
              const SizedBox(height: 16),
              const Text('Warna',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ColorPickerRow(
                selected: _color,
                onChanged: (value) => setState(() => _color = value),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(financeControllerProvider);
    final existing = widget.category;
    if (existing == null) {
      await controller.createCategory(
        name: _nameController.text.trim(),
        kind: _kind,
        iconCodePoint: _icon,
        colorValue: _color,
      );
    } else {
      await controller.saveCategory(existing.copyWith(
        name: _nameController.text.trim(),
        kind: _kind,
        iconCodePoint: _icon,
        colorValue: _color,
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
