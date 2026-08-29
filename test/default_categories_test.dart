import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/data/database/in_memory_database.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/repositories/category_repository.dart';

void main() {
  late InMemoryDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = InMemoryDatabase();
    repo = CategoryRepository(db);
  });

  const expectedIncome = ['Gaji', 'Bonus', 'Freelance', 'Bisnis', 'Lainnya'];
  const expectedExpense = [
    'Makanan',
    'Transportasi',
    'Tempat Tinggal',
    'Tagihan',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Keluarga',
    'Lainnya',
  ];

  test('seeds the exact basic categories, all marked as default', () async {
    await repo.seedDefaultsIfEmpty();
    final categories = await repo.getAll();

    expect(categories.every((c) => c.isDefault), isTrue);
    expect(
      categories
          .where((c) => c.kind == CategoryKind.income)
          .map((c) => c.name)
          .toSet(),
      expectedIncome.toSet(),
    );
    expect(
      categories
          .where((c) => c.kind == CategoryKind.expense)
          .map((c) => c.name)
          .toSet(),
      expectedExpense.toSet(),
    );
  });

  test('running the seed again never duplicates', () async {
    await repo.seedDefaultsIfEmpty();
    final first = (await repo.getAll()).length;
    await repo.seedDefaultsIfEmpty();
    await repo.seedDefaultsIfEmpty();
    expect((await repo.getAll()).length, first);
  });

  test('does not seed when the box already has any category', () async {
    await repo.create(
      name: 'Kopi',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    await repo.seedDefaultsIfEmpty();
    final categories = await repo.getAll();
    expect(categories, hasLength(1));
    expect(categories.single.name, 'Kopi');
  });

  test('default categories cannot be deleted', () async {
    await repo.seedDefaultsIfEmpty();
    final gaji = (await repo.getAll()).firstWhere((c) => c.name == 'Gaji');
    await expectLater(() => repo.delete(gaji.id), throwsStateError);
    expect((await repo.getAll()).any((c) => c.id == gaji.id), isTrue);
  });

  test('default categories cannot be edited', () async {
    await repo.seedDefaultsIfEmpty();
    final gaji = (await repo.getAll()).firstWhere((c) => c.name == 'Gaji');
    await expectLater(
      () => repo.save(gaji.copyWith(name: 'Gaji Pokok')),
      throwsStateError,
    );
  });

  test('custom categories keep full CRUD', () async {
    final created = await repo.create(
      name: 'Langganan',
      kind: CategoryKind.expense,
      iconCodePoint: 1,
      colorValue: 1,
    );
    expect(created.isDefault, isFalse);

    await repo.save(created.copyWith(name: 'Langganan Streaming'));
    expect(
      (await repo.getAll()).single.name,
      'Langganan Streaming',
    );

    await repo.delete(created.id);
    expect(await repo.getAll(), isEmpty);
  });
}
