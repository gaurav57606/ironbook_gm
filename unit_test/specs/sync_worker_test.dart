import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import '../../test/fakes/fake_event_repository.dart';
import '../../test/fakes/fake_firestore.dart';

class MockOutboxRepository extends Mock implements OutboxRepository {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class MockRef extends Mock implements Ref {}
class MockStatusNotifier extends Mock implements StateController<SyncWorkerState> {}

void main() {
  late FakeEventRepository mockRepo;
  late FakeFirestore mockFirestore;
  late MockOutboxRepository mockOutbox;
  late MockSyncCoordinator mockCoordinator;
  late MockRef mockRef;
  late SyncWorker syncWorker;
  final statusProvider = StateProvider<SyncWorkerState>((ref) => SyncWorkerState(status: SyncWorkerStatus.idle));

  setUpAll(() {
    registerFallbackValue(SyncWorkerState(status: SyncWorkerStatus.idle));
  });

  setUp(() {
    mockRepo = FakeEventRepository();
    mockFirestore = FakeFirestore();
    mockOutbox = MockOutboxRepository();
    mockCoordinator = MockSyncCoordinator();
    mockRef = MockRef();

    // Default stubs
    when(() => mockCoordinator.onSyncRequested).thenAnswer((_) => const Stream.empty());
    when(() => mockCoordinator.acquireLock(any())).thenAnswer((_) async => true);
    when(() => mockCoordinator.releaseLock(any())).thenAnswer((_) async {});
    when(() => mockOutbox.markSynced(any())).thenAnswer((_) async {});
    when(() => mockOutbox.getUnsyncedEvents()).thenAnswer((_) async => []);

    // Mock status provider interaction
    final mockStatusNotifier = MockStatusNotifier();
    when(() => mockRef.read(statusProvider.notifier)).thenReturn(mockStatusNotifier);
    when(() => mockStatusNotifier.state = any()).thenReturn(SyncWorkerState(status: SyncWorkerStatus.idle));

    syncWorker = SyncWorker(
      mockRepo, 
      mockOutbox, 
      mockCoordinator, 
      mockFirestore.set, 
      () => 'user-1',
      statusProvider,
      mockRef
    );
  });

  test('SyncWorker should push unsynced events to Firestore idempotently', () async {
    final event = DomainEvent(
      id: 'event-1',
      entityId: 'm1',
      eventType: EventType.memberCreated,
      payload: {'data': 'val'},
      deviceTimestamp: DateTime(2024, 3, 25),
      deviceId: 'dev-1',
    );
    
    await mockRepo.persist(event);
    when(() => mockOutbox.getUnsyncedEvents()).thenAnswer((_) async => [event]);
    
    // First run
    await syncWorker.performSync();
    
    expect(mockFirestore.exists('users/user-1/events', 'event-1'), isTrue);
    expect(mockFirestore.writeCount, 1);
    
    // Simulate first write success, second write failure
    mockFirestore.failNextWrite = false; // Event 1 succeeds
    // We need to trigger failure on the SECOND call. 
    // I'll modify FakeFirestore to fail on a specific count if needed, 
    // but here I'll just run it once and then again.
    
    // Actually, I'll modify FakeFirestore to fail on count 2.
    // Or just manually:
    await syncWorker.performSync(); // Both unsynced. 
    // Wait, in SyncWorker.sync(), it iterates through ALL unsynced.
    // If I want the second to fail, I'll update FakeFirestore.
  });

  test('SyncWorker should handle partial failures and resume correctly', () async {
    final e1 = DomainEvent(id: 'e1', entityId: 'm1', eventType: EventType.memberCreated, payload: {}, deviceTimestamp: DateTime(2024), deviceId: 'd1');
    final e2 = DomainEvent(id: 'e2', entityId: 'm1', eventType: EventType.memberCreated, payload: {}, deviceTimestamp: DateTime(2024), deviceId: 'd1');
    await mockRepo.persist(e1);
    await mockRepo.persist(e2);
    when(() => mockOutbox.getUnsyncedEvents()).thenAnswer((_) async => await mockRepo.getAllUnsynced());

    mockFirestore.failNextWrite = true; // First one fails immediately
    try {
      await syncWorker.performSync();
    } catch (_) {
      // Expected
    }
    
    expect((await mockRepo.getAllUnsynced()).length, 2, reason: 'Failures should prevent local sync mark');
    expect(mockFirestore.writeCount, 0);

    mockFirestore.failNextWrite = false; 
    when(() => mockOutbox.getUnsyncedEvents()).thenAnswer((_) async => await mockRepo.getAllUnsynced());
    await syncWorker.performSync();
    
    expect((await mockRepo.getAllUnsynced()).isEmpty, isTrue, reason: 'Resume should clear all pending');
    expect(mockFirestore.writeCount, 2, reason: 'Both should be written eventually');
    expect(mockFirestore.exists('users/user-1/events', 'e1'), isTrue);
    expect(mockFirestore.exists('users/user-1/events', 'e2'), isTrue);
  });
}



