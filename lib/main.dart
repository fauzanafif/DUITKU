import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:duitku/app/duitku_app.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/hive_database.dart';
import 'package:duitku/data/repositories/category_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final database = HiveDatabase();
  await database.init();

  // Basic categories are available from the very first launch. This is a
  // no-op on every later launch: it only seeds when the category box is
  // completely empty, so it never duplicates or overwrites anything.
  await CategoryRepository(database).seedDefaultsIfEmpty();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const DuitkuApp(),
    ),
  );
}
