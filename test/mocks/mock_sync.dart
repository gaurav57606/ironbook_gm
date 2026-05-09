import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';

class MockSyncWorker extends Mock implements SyncWorker {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}

MockSyncWorker createMockSyncWorker() {
  final worker = MockSyncWorker();
  when(() => worker.startPeriodicSync(any())).thenReturn(null);
  when(() => worker.performSync()).thenAnswer((_) async => {});
  return worker;
}

MockSyncCoordinator createMockSyncCoordinator() {
  final coordinator = MockSyncCoordinator();
  when(() => coordinator.triggerSync()).thenReturn(null);
  when(() => coordinator.onSyncRequested).thenAnswer((_) => const Stream.empty());
  return coordinator;
}
