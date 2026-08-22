import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:duitku/core/finance/date_range.dart';
import 'package:duitku/core/finance/finance_calculator.dart';
import 'package:duitku/core/utils/formatters.dart';
import 'package:duitku/core/utils/json_utils.dart';
import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/budget.dart';
import 'package:duitku/data/models/category.dart';
import 'package:duitku/data/models/allowance_limit.dart';
import 'package:duitku/data/models/debt.dart';
import 'package:duitku/data/models/recurring_rule.dart';
import 'package:duitku/data/models/saving_goal.dart';
import 'package:duitku/data/models/transaction.dart';

class BackupPayload {
  const BackupPayload({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.savingGoals,
    required this.debts,
    required this.recurringRules,
    required this.allowanceLimits,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final List<TransactionRecord> transactions;
  final List<Budget> budgets;
  final List<SavingGoal> savingGoals;
  final List<Debt> debts;
  final List<RecurringRule> recurringRules;
  final List<AllowanceLimit> allowanceLimits;

  int get totalRecords =>
      accounts.length +
      categories.length +
      transactions.length +
      budgets.length +
      savingGoals.length +
      debts.length +
      recurringRules.length +
      allowanceLimits.length;
}

enum RestoreMode {
  /// Wipes existing financial data and writes the backup as-is.
  replace,

  /// Keeps existing rows; entries whose id already exists are skipped.
  merge,
}

class BackupService {
  BackupService(this._db);

  static const int formatVersion = 1;

  final DuitkuDatabase _db;

  Future<Map<String, dynamic>> buildBackupJson() async {
    return {
      'app': 'DUITKU',
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': (await _db.readAccounts()).map((e) => e.toJson()).toList(),
      'categories':
          (await _db.readCategories()).map((e) => e.toJson()).toList(),
      'transactions':
          (await _db.readTransactions()).map((e) => e.toJson()).toList(),
      'budgets': (await _db.readBudgets()).map((e) => e.toJson()).toList(),
      'savingGoals':
          (await _db.readSavingGoals()).map((e) => e.toJson()).toList(),
      'debts': (await _db.readDebts()).map((e) => e.toJson()).toList(),
      'recurringRules':
          (await _db.readRecurringRules()).map((e) => e.toJson()).toList(),
      'allowanceLimits':
          (await _db.readAllowanceLimits()).map((e) => e.toJson()).toList(),
    };
  }

  Future<File> exportJson() async {
    final json = await buildBackupJson();
    final directory = await _backupDirectory();
    final file = File(
      '${directory.path}/duitku-backup-${_timestamp()}.json',
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    return file;
  }

  Future<File> exportCsv() async {
    final transactions = await _db.readTransactions()
      ..sort((a, b) => a.transactionDateTime.compareTo(b.transactionDateTime));
    final accounts = {for (final a in await _db.readAccounts()) a.id: a.name};
    final categories = {
      for (final c in await _db.readCategories()) c.id: c.name
    };

    final buffer = StringBuffer()
      ..writeln('tanggal,waktu,tipe,judul,kategori,akun,akun_tujuan,nominal,catatan');
    for (final tx in transactions) {
      buffer.writeln([
        Formatters.shortDate(tx.transactionDateTime),
        Formatters.time(tx.transactionDateTime),
        tx.type.name,
        _csv(tx.title),
        _csv(categories[tx.categoryId] ?? ''),
        _csv(accounts[tx.accountId] ?? ''),
        _csv(accounts[tx.destinationAccountId] ?? ''),
        tx.amount.toStringAsFixed(0),
        _csv(tx.note ?? ''),
      ].join(','));
    }

    final directory = await _backupDirectory();
    final file = File('${directory.path}/duitku-transaksi-${_timestamp()}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Renders a one-cycle report (summary + category breakdown + full
  /// transaction list) as a PDF, reusing the exact same calculations the
  /// on-screen Laporan tab uses so the numbers always match.
  ///
  /// Building the document is pure (no file I/O, no platform channels) so
  /// it is unit-testable on its own — [exportMonthlyReportPdf] just adds
  /// the file-writing step, mirroring [exportJson]/[exportCsv].
  static pw.Document buildMonthlyReportDocument({
    required DateTime month,
    required List<Account> accounts,
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required String currencyCode,
    int payday = 1,
  }) {
    final range = DateRange.financialMonth(month.year, month.month, payday);
    final cashFlow = FinanceCalculator.cashFlow(transactions, range);
    final breakdown =
        FinanceCalculator.breakdownByCategory(transactions, range);
    final periodTransactions =
        FinanceCalculator.inRange(transactions, range).toList()
          ..sort((a, b) =>
              a.transactionDateTime.compareTo(b.transactionDateTime));

    final categoryNames = {for (final c in categories) c.id: c.name};
    final accountNames = {for (final a in accounts) a.id: a.name};

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            text: 'Laporan DUITKU - ${Formatters.monthYear(month)}',
          ),
          pw.SizedBox(height: 12),
          pw.Text('Ringkasan',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Pemasukan', 'Pengeluaran', 'Arus Kas Bersih'],
            data: [
              [
                Formatters.currency(cashFlow.income,
                    currencyCode: currencyCode),
                Formatters.currency(cashFlow.expense,
                    currencyCode: currencyCode),
                Formatters.currency(cashFlow.net, currencyCode: currencyCode),
              ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Pengeluaran per Kategori',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          if (breakdown.isEmpty)
            pw.Text('Belum ada pengeluaran pada periode ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Kategori', 'Total', 'Persentase'],
              data: [
                for (final entry in breakdown)
                  [
                    categoryNames[entry.categoryId] ?? 'Tanpa kategori',
                    Formatters.currency(entry.total,
                        currencyCode: currencyCode),
                    Formatters.percent(entry.share),
                  ],
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Text('Transaksi',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          if (periodTransactions.isEmpty)
            pw.Text('Belum ada transaksi pada periode ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Tanggal',
                'Judul',
                'Tipe',
                'Kategori',
                'Akun',
                'Nominal',
              ],
              data: [
                for (final tx in periodTransactions)
                  [
                    Formatters.shortDate(tx.transactionDateTime),
                    tx.title,
                    tx.type.label,
                    categoryNames[tx.categoryId] ?? '-',
                    accountNames[tx.accountId] ?? '-',
                    Formatters.currency(tx.amount,
                        currencyCode: currencyCode),
                  ],
              ],
            ),
        ],
      ),
    );

    return doc;
  }

  Future<File> exportMonthlyReportPdf({
    required DateTime month,
    required List<Account> accounts,
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required String currencyCode,
    int payday = 1,
  }) async {
    final doc = buildMonthlyReportDocument(
      month: month,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      currencyCode: currencyCode,
      payday: payday,
    );
    final directory = await _backupDirectory();
    final file = File('${directory.path}/duitku-laporan-${_timestamp()}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Parses and validates a backup file without touching the database.
  BackupPayload parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw BackupFormatException('File bukan JSON yang valid.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('Struktur file backup tidak dikenali.');
    }
    if (decoded['app'] != 'DUITKU') {
      throw BackupFormatException('File ini bukan backup DUITKU.');
    }
    final version = decoded['version'];
    if (version is! int || version > formatVersion) {
      throw BackupFormatException(
          'Versi backup tidak didukung oleh aplikasi ini.');
    }

    final payload = BackupPayload(
      accounts: _parseList(decoded['accounts'], Account.fromJson),
      categories: _parseList(decoded['categories'], Category.fromJson),
      transactions:
          _parseList(decoded['transactions'], TransactionRecord.fromJson),
      budgets: _parseList(decoded['budgets'], Budget.fromJson),
      savingGoals: _parseList(decoded['savingGoals'], SavingGoal.fromJson),
      debts: _parseList(decoded['debts'], Debt.fromJson),
      recurringRules:
          _parseList(decoded['recurringRules'], RecurringRule.fromJson),
      allowanceLimits: _parseList(
          decoded['allowanceLimits'], AllowanceLimit.fromJson),
    );

    _assertUniqueIds(payload.accounts.map((e) => e.id), 'akun');
    _assertUniqueIds(payload.categories.map((e) => e.id), 'kategori');
    _assertUniqueIds(payload.transactions.map((e) => e.id), 'transaksi');
    _assertUniqueIds(payload.budgets.map((e) => e.id), 'budget');
    _assertUniqueIds(payload.savingGoals.map((e) => e.id), 'target');
    _assertUniqueIds(payload.debts.map((e) => e.id), 'cicilan');
    _assertUniqueIds(
        payload.recurringRules.map((e) => e.id), 'transaksi berulang');
    _assertUniqueIds(
        payload.allowanceLimits.map((e) => e.id), 'limit uang jajan');

    final accountIds = payload.accounts.map((e) => e.id).toSet();
    final categoryIds = payload.categories.map((e) => e.id).toSet();
    final debtIds = payload.debts.map((e) => e.id).toSet();
    for (final tx in payload.transactions) {
      if (!accountIds.contains(tx.accountId)) {
        throw BackupFormatException(
            'Transaksi "${tx.title}" merujuk akun yang tidak ada di backup.');
      }
      final destination = tx.destinationAccountId;
      if (destination != null && !accountIds.contains(destination)) {
        throw BackupFormatException(
            'Transaksi "${tx.title}" merujuk akun tujuan yang tidak ada.');
      }
      final category = tx.categoryId;
      if (category != null && !categoryIds.contains(category)) {
        throw BackupFormatException(
            'Transaksi "${tx.title}" merujuk kategori yang tidak ada.');
      }
      final debtId = tx.debtId;
      if (debtId != null && !debtIds.contains(debtId)) {
        throw BackupFormatException(
            'Transaksi "${tx.title}" merujuk cicilan yang tidak ada.');
      }
    }
    for (final budget in payload.budgets) {
      if (!categoryIds.contains(budget.categoryId)) {
        throw BackupFormatException(
            'Budget merujuk kategori yang tidak ada di backup.');
      }
    }
    for (final rule in payload.recurringRules) {
      if (!accountIds.contains(rule.accountId)) {
        throw BackupFormatException(
            'Transaksi berulang "${rule.title}" merujuk akun yang tidak ada.');
      }
      final category = rule.categoryId;
      if (category != null && !categoryIds.contains(category)) {
        throw BackupFormatException(
            'Transaksi berulang "${rule.title}" merujuk kategori yang tidak ada.');
      }
    }
    for (final limit in payload.allowanceLimits) {
      if (!accountIds.contains(limit.accountId)) {
        throw BackupFormatException(
            'Limit uang jajan merujuk akun yang tidak ada di backup.');
      }
    }
    return payload;
  }

  Future<void> restore(BackupPayload payload, RestoreMode mode) async {
    if (mode == RestoreMode.replace) {
      await _db.clearFinancialData();
    }

    final existingAccounts = (await _db.readAccounts()).map((e) => e.id).toSet();
    final existingCategories =
        (await _db.readCategories()).map((e) => e.id).toSet();
    final existingTransactions =
        (await _db.readTransactions()).map((e) => e.id).toSet();
    final existingBudgets = (await _db.readBudgets()).map((e) => e.id).toSet();
    final existingGoals =
        (await _db.readSavingGoals()).map((e) => e.id).toSet();
    final existingDebts = (await _db.readDebts()).map((e) => e.id).toSet();
    final existingRecurringRules =
        (await _db.readRecurringRules()).map((e) => e.id).toSet();
    final existingAllowanceLimits =
        (await _db.readAllowanceLimits()).map((e) => e.id).toSet();

    for (final account in payload.accounts) {
      if (existingAccounts.contains(account.id)) continue;
      await _db.writeAccount(account);
    }
    for (final category in payload.categories) {
      if (existingCategories.contains(category.id)) continue;
      await _db.writeCategory(category);
    }
    for (final tx in payload.transactions) {
      if (existingTransactions.contains(tx.id)) continue;
      await _db.writeTransaction(tx);
    }
    for (final budget in payload.budgets) {
      if (existingBudgets.contains(budget.id)) continue;
      await _db.writeBudget(budget);
    }
    for (final goal in payload.savingGoals) {
      if (existingGoals.contains(goal.id)) continue;
      await _db.writeSavingGoal(goal);
    }
    for (final debt in payload.debts) {
      if (existingDebts.contains(debt.id)) continue;
      await _db.writeDebt(debt);
    }
    for (final rule in payload.recurringRules) {
      if (existingRecurringRules.contains(rule.id)) continue;
      await _db.writeRecurringRule(rule);
    }
    for (final limit in payload.allowanceLimits) {
      if (existingAllowanceLimits.contains(limit.id)) continue;
      await _db.writeAllowanceLimit(limit);
    }
  }

  Future<List<File>> listBackupFiles() async {
    final directory = await _backupDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<Directory> _backupDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory('${base.path}/duitku-backup');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return <T>[];
    if (raw is! List) {
      throw BackupFormatException('Bagian backup tidak berbentuk daftar.');
    }
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static void _assertUniqueIds(Iterable<String> ids, String label) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) {
        throw BackupFormatException('Ada ID $label duplikat di file backup.');
      }
    }
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
