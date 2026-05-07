import '../local/drift/outbox_database.dart';
import '../local/models/app_settings_model.dart';
import 'package:drift/drift.dart';

abstract class ISettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
}

class DriftSettingsRepository implements ISettingsRepository {
  final OutboxDatabase _db;

  DriftSettingsRepository(this._db);

  @override
  Future<AppSettings> getSettings() async {
    final row = await _db.select(_db.appSettingsTable).getSingleOrNull();
    if (row == null) return AppSettings();

    return AppSettings(
      gstRate: row.gstRate,
      expiryReminderDays: row.expiryReminderDays,
      whatsappReminders: row.whatsappReminders,
      biometricEnabled: row.biometricEnabled,
      useBiometrics: row.useBiometrics,
      businessType: row.businessType,
      lastBackupAt: row.lastBackupAt,
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _db.into(_db.appSettingsTable).insertOnConflictUpdate(
      AppSettingsTableCompanion.insert(
        id: const Value(1),
        gstRate: Value(settings.gstRate),
        expiryReminderDays: Value(settings.expiryReminderDays),
        whatsappReminders: Value(settings.whatsappReminders),
        biometricEnabled: Value(settings.biometricEnabled),
        useBiometrics: Value(settings.useBiometrics),
        businessType: Value(settings.businessType),
        lastBackupAt: Value(settings.lastBackupAt),
      ),
    );
  }
}
