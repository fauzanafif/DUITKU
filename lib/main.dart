import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:duitku/app/duitku_app.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/hive_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final database = HiveDatabase();
  await database.init();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const DuitkuApp(),
    ),
  );
}
