import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/app/duitku_app.dart';
import 'package:duitku/data/database/hive_database.dart';

void main() {
  testWidgets('DUITKU app loads successfully', (WidgetTester tester) async {
    // Initialize database for testing
    final database = HiveDatabase();
    await database.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: const DuitkuApp(),
      ),
    );

    // Verify MaterialApp exists
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
