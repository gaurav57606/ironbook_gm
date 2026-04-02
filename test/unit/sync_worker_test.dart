import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import '../fakes/fake_event_repository.dart';
import '../fakes/fake_firestore.dart';

void main() {
  late FakeEventRepository mockRepo;
  late FakeFirestore mockFirestore;
  late SyncWorker syncWorker;

  setUp(() {
    mockRepo = FakeEventRepository();
    mockFirestore = FakeFirestore();
    syncWorker = SyncWorker(mockRepo, mockFirestore.set, () => 'user-1');
  });

  test('SyncWorker should push unsynced events to Firestore idempotently', () async {
    final event = DomainEvent(
      id: 'event-1',
      entityId: 'm1',
      eventType: 'TEST',
      payload: {'data': 'val'},
      deviceTimestamp: DateTime(2024, 3, 25),
      deviceId: 'dev-1',
    );
    
    await mockRepo.persist(event);
    
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
    final e1 = DomainEvent(id: 'e1', entityId: 'm1', eventType: 'T1', payload: {}, deviceTimestamp: DateTime(2024), deviceId: 'd1');
    final e2 = DomainEvent(id: 'e2', entityId: 'm1', eventType: 'T2', payload: {}, deviceTimestamp: DateTime(2024), deviceId: 'd1');
    await mockRepo.persist(e1);
    await mockRepo.persist(e2);

    mockFirestore.failNextWrite = true; // First one fails immediately
    await syncWorker.performSync();
    
    expect(mockRepo.getAllUnsynced().length, 2, reason: 'Failures should prevent local sync mark');
    expect(mockFirestore.writeCount, 0);

    mockFirestore.failNextWrite = false; 
    await syncWorker.performSync();
    
    expect(mockRepo.getAllUnsynced().isEmpty, isTrue, reason: 'Resume should clear all pending');
    expect(mockFirestore.writeCount, 2, reason: 'Both should be written eventually');
    expect(mockFirestore.exists('users/user-1/events', 'e1'), isTrue);
    expect(mockFirestore.exists('users/user-1/events', 'e2'), isTrue);
  });
}
