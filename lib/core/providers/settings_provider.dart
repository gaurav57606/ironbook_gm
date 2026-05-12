import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/app_settings_model.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/local/models/domain_event_model.dart';
import '../services/hmac_service.dart';
import 'base_providers.dart';

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftSettingsRepository(db);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return SettingsNotifier(repo, eventRepo, hmac);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final ISettingsRepository _repo;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  StreamSubscription? _eventSubscription;
  String _deviceId = 'device-unknown';

  SettingsNotifier(this._repo, this._eventRepo, this._hmac) : super(AppSettings()) {
    _init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Listen for events
    _eventSubscription = _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.settingsChanged) {
        debugPrint('[STATE] SettingsNotifier: Processing settings event');
        await _repo.applyEvent(event);
        if (mounted) {
          state = await _repo.getSettings();
        }
      }
    });

    // 2. Load initial state
    state = await _repo.getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    // Emit event
    final event = DomainEvent(
      entityId: 'settings',
      eventType: EventType.settingsChanged,
      deviceId: _deviceId,
      deviceTimestamp: DateTime.now(),
      payload: settings.toJson(),
    );

    await _eventRepo.persist(event);
    await _repo.updateSettings(settings);
  }

  Future<void> rebuildCache() async {
    debugPrint('[STATE] SettingsNotifier: Full rebuild triggered');
    final events = await _eventRepo.getByEntityId('settings');
    if (events.isNotEmpty) {
      events.sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));
      final latest = events.last;
      await _repo.applyEvent(latest);
      if (mounted) {
        state = await _repo.getSettings();
      }
    }
  }
}
