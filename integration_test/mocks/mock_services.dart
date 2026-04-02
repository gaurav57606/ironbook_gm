import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/security/pin_service.dart';

class MockPinService extends Mock implements PinService {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockHmacService extends Mock implements HmacService {}
