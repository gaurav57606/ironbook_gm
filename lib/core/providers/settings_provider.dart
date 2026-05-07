import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/app_settings_model.dart';
import '../data/repositories/settings_repository.dart';
import 'base_providers.dart';

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftSettingsRepository(db);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final ISettingsRepository _repo;

  SettingsNotifier(this._repo) : super(AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _repo.updateSettings(settings);
    state = settings;
  }
}
