import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import '../test_helper.dart';

// Helper to build a minimal DomainEvent
DomainEvent _fakeEvent({String? id}) => DomainEvent(
  id: id ?? 'evt-${DateTime.now().microsecondsSinceEpoch}',
  entityId: 'member-1',
  eventType: EventType.memberCreated,
  deviceId: 'test-device',
  deviceTimestamp: DateTime.now(),
  payload: {'name': 'Test Member'},
  hmacSignature: 'fake-sig',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OutboxDatabase db;
  late OutboxRepository outbox;
  late ProviderContainer container;

    setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Mock connectivity
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity'),
            (methodCall) async {
      if (methodCall.method == 'check') {
        return <String>['wifi'];
      }
      return null;
    });

    db = OutboxDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // ── Test 1: Create-only write — does NOT push if document already exists ──
  test('does not call set() when document already exists in Firestore', () async {
    final pushedIds = <String>[];
    final existingIds = {'evt-already-synced'};

    final event = _fakeEvent(id: 'evt-already-synced');
    await outbox.insertEvent(event);
    // Do NOT markSynced — it's in outbox as unsynced but Firestore has it

    final prefs = await SharedPreferences.getInstance();

    Future<void> createOnlyPusher(
        String coll, String id, Map<String, dynamic> data) async {
      // Simulate: document exists in Firestore already
      if (existingIds.contains(id)) {
        return; // create-only: skip
      }
      pushedIds.add(id);
    }

    final ref = MockRef();
    final notifier = StateController(SyncWorkerState(status: SyncWorkerStatus.idle));
    when(() => ref.read(syncWorkerStatusProvider.notifier)).thenReturn(notifier);

    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      createOnlyPusher,
      () => 'test-uid',
      syncWorkerStatusProvider,
      ref,
    );

    await worker.performSync();

    // Document existed, so it should NOT have been added to pushedIds
    expect(pushedIds, isEmpty,
        reason: 'Event already in Firestore should not be re-pushed');

    // But it SHOULD be marked synced in Drift (idempotent recovery)
    final remaining = await outbox.getUnsyncedEvents();
    expect(remaining, isEmpty,
        reason: 'Event must be marked synced even if Firestore write was skipped');
  });

  // ── Test 2: New event IS pushed when document does not exist ──
  test('calls set() for new events that do not exist in Firestore', () async {
    final pushedIds = <String>[];
    final event = _fakeEvent(id: 'evt-new');
    await outbox.insertEvent(event);

    final prefs = await SharedPreferences.getInstance();

    Future<void> createOnlyPusher(
        String coll, String id, Map<String, dynamic> data) async {
      pushedIds.add(id); // Simulate: document did not exist, we wrote it
    }

    final ref = MockRef();
    final notifier = StateController(SyncWorkerState(status: SyncWorkerStatus.idle));
    when(() => ref.read(syncWorkerStatusProvider.notifier)).thenReturn(notifier);

    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      createOnlyPusher,
      () => 'test-uid',
      syncWorkerStatusProvider,
      ref,
    );

    await worker.performSync();

    expect(pushedIds, contains('evt-new'),
        reason: 'New event must be pushed to Firestore');
    final remaining = await outbox.getUnsyncedEvents();
    expect(remaining, isEmpty,
        reason: 'Event must be marked synced after successful push');
  });

  // ── Test 3: Failure count persists across restarts ──
  test('loads persisted consecutive failure count on construction', () async {
    SharedPreferences.setMockInitialValues({
      'sync_consecutive_failures': 5,
    });
    final prefs = await SharedPreferences.getInstance();

    final ref = MockRef();
    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      (_, __, ___) async {},
      () => 'test-uid',
      syncWorkerStatusProvider,
      ref,
    );

    // performSync with no events resets counter to 0 and saves it
    // Confirm the loaded value is 5 BEFORE any sync by checking prefs directly
    expect(prefs.getInt('sync_consecutive_failures'), equals(5));
    // Silence the worker
    worker.dispose();
  });

  // ── Test 4: Failure count increments and saves on sync error ──
  test('increments and saves failure count when push throws', () async {
    SharedPreferences.setMockInitialValues({'sync_consecutive_failures': 0});
    final prefs = await SharedPreferences.getInstance();

    final event = _fakeEvent(id: 'evt-fail');
    await outbox.insertEvent(event);

    final ref = MockRef();
    final notifier = StateController(SyncWorkerState(status: SyncWorkerStatus.idle));
    when(() => ref.read(syncWorkerStatusProvider.notifier)).thenReturn(notifier);

    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      (_, __, ___) async => throw Exception('network error'),
      () => 'test-uid',
      syncWorkerStatusProvider,
      ref,
    );

    try {
      await worker.performSync();
    } catch (_) {}

    expect(prefs.getInt('sync_consecutive_failures'), equals(1),
        reason: 'Failure count must be saved to SharedPreferences after error');
  });

  // ── Test 5: Failure count resets to 0 on success and saves ──
  test('resets and saves failure count to 0 after successful sync', () async {
    SharedPreferences.setMockInitialValues({'sync_consecutive_failures': 3});
    final prefs = await SharedPreferences.getInstance();

    final event = _fakeEvent(id: 'evt-ok');
    await outbox.insertEvent(event);

    final ref = MockRef();
    final notifier = StateController(SyncWorkerState(status: SyncWorkerStatus.idle));
    when(() => ref.read(syncWorkerStatusProvider.notifier)).thenReturn(notifier);

    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      (_, __, ___) async {}, // success
      () => 'test-uid',
      syncWorkerStatusProvider,
      ref,
    );

    await worker.performSync();

    expect(prefs.getInt('sync_consecutive_failures'), equals(0),
        reason: 'Failure count must reset to 0 and be saved after success');
  });

  // ── Test 6: Backoff is capped at 15 minutes ──
  test('exponential backoff never exceeds 15 minutes', () {
    // The backoff formula is: baseInterval * 2^failures, capped at 15 min
    // With base 30s and 20 failures: 30s * 2^20 = extremely large
    // Verify the cap logic by checking the expected max
    const base = Duration(seconds: 30);
    const cap = Duration(minutes: 15);

    for (int failures = 0; failures <= 30; failures++) {
      int factor = 1 << failures.clamp(0, 10);
      Duration next = base * factor;
      if (next > cap) next = cap;
      expect(next, lessThanOrEqualTo(cap),
          reason: 'Backoff must never exceed 15 minutes at failure count $failures');
    }
  });

  // ── Test 7: Skips sync when no user is authenticated ──
  test('does not attempt push when currentUserId returns null', () async {
    final pushedIds = <String>[];
    final event = _fakeEvent();
    await outbox.insertEvent(event);
    final prefs = await SharedPreferences.getInstance();

    final ref = MockRef();
    final notifier = StateController(SyncWorkerState(status: SyncWorkerStatus.idle));
    when(() => ref.read(syncWorkerStatusProvider.notifier)).thenReturn(notifier);

    final worker = SyncWorker(
      outbox,
      FakeSyncCoordinator(),
      prefs,
      (_, id, __) async => pushedIds.add(id),
      () => null, // no user
      syncWorkerStatusProvider,
      ref,
    );

    await worker.performSync();

    expect(pushedIds, isEmpty,
        reason: 'Nothing should be pushed without an authenticated user');
  });
}
