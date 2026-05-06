import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _init();
  }

  void _init() {
    if (!Hive.isBoxOpen('settings')) return;
    final box = Hive.box<AppSettings>('settings');
    state = box.get('settings', defaultValue: AppSettings())!;
    
    box.listenable().addListener(() {
      state = box.get('settings', defaultValue: AppSettings())!;
    });
  }

  Future<void> updateSettings(AppSettings settings) async {
    final box = Hive.box<AppSettings>('settings');
    await box.put('settings', settings);
  }
}









