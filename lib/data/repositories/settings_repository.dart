import 'package:duitku/data/database/duitku_database.dart';
import 'package:duitku/data/models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final DuitkuDatabase _db;

  Future<AppSettings> get() => _db.readSettings();

  Future<void> save(AppSettings settings) => _db.writeSettings(settings);
}
