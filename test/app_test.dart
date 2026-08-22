import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/app/duitku_app.dart';
import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/data/database/in_memory_database.dart';

void main() {
  testWidgets('DUITKU app loads successfully', (WidgetTester tester) async {
    final database = InMemoryDatabase();
    await database.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const DuitkuApp(),
      ),
    );

    // Verify MaterialApp exists
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
