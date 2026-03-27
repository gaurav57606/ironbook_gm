import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';

class FakeRepo implements IEventRepository {
  @override
  Future<void> persist(DomainEvent event) async {}
  @override
  List<DomainEvent> getAllUnsynced() => [];
  @override
  DomainEvent? getById(String id) => null;
  @override
  List<DomainEvent> getByEntityId(String entityId) => [];
  @override
  Future<void> markAsSynced(String eventId) async {}
  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class FakeAuth extends AuthNotifier {
  FakeAuth() : super(
    const FlutterSecureStorage(), 
    null as dynamic, 
    null as dynamic, 
    FakeRepo(), 
    null as dynamic,
    null as dynamic
  ) {
    state = AuthState(
      isAuthenticated: true,
      unlocked: true,
      isPinSetup: true,
      isFirstLaunch: false,
      isLoading: false,
      settings: AppSettings(),
      owner: OwnerProfile(gymName: 'Test Gym', ownerName: 'Tester', phone: '12345', address: ''),
    );
  }
}
