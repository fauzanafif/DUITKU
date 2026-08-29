import 'package:duitku/core/constants/app_defaults.dart';
import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/category.dart';
import 'package:uuid/uuid.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final DuitkuDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final categories = await _db.readCategories();
    categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return categories;
  }

  Future<Category> create({
    required String name,
    required CategoryKind kind,
    required int iconCodePoint,
    required int colorValue,
    bool isDefault = false,
  }) async {
    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      name: name.trim(),
      kind: kind,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
    );
    await _db.writeCategory(category);
    return category;
  }

  /// Default (system) categories are read-only — they can never be edited
  /// or deleted, so the app is always usable out of the box.
  Future<void> save(Category category) async {
    if (category.isDefault) {
      throw StateError('Kategori bawaan tidak dapat diubah.');
    }
    await _db.writeCategory(category);
  }

  /// Deleting a used category is only allowed when the caller supplies a
  /// [reassignTo] category, so no transaction is left dangling.
  Future<void> delete(String id, {String? reassignTo}) async {
    final categories = await _db.readCategories();
    if (categories.any((c) => c.id == id && c.isDefault)) {
      throw StateError('Kategori bawaan tidak dapat dihapus.');
    }
    final transactions = await _db.readTransactions();
    final used = transactions.where((tx) => tx.categoryId == id).toList();
    if (used.isNotEmpty) {
      if (reassignTo == null) {
        throw StateError(
          'Kategori masih dipakai ${used.length} transaksi. '
          'Pilih kategori pengganti terlebih dahulu.',
        );
      }
      for (final tx in used) {
        await _db.writeTransaction(tx.copyWith(categoryId: reassignTo));
      }
    }
    final budgets = await _db.readBudgets();
    for (final budget in budgets.where((b) => b.categoryId == id)) {
      if (reassignTo == null) {
        await _db.deleteBudget(budget.id);
      } else {
        await _db.writeBudget(budget.copyWith(categoryId: reassignTo));
      }
    }
    await _db.deleteCategory(id);
  }

  Future<void> seedDefaultsIfEmpty() async {
    final existing = await _db.readCategories();
    if (existing.isNotEmpty) return;
    for (final seed in AppDefaults.categories) {
      await create(
        name: seed.name,
        kind: seed.kind,
        iconCodePoint: seed.icon.codePoint,
        colorValue: seed.color.toARGB32(),
        isDefault: true,
      );
    }
  }
}
