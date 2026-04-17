import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';

class FakeRepo implements IEventRepository {
  @override
  Future<void> persist(DomainEvent event) async {}
  @override
  Future<List<DomainEvent>> getAllUnsynced() async => [];
  @override
  Future<DomainEvent?> getById(String id) async => null;
  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async => [];
  @override
  Future<List<DomainEvent>> getAll() async => [];
  @override
  Future<void> markAsSynced(String eventId) async {}
  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class FakeHmacService extends HmacService {
  FakeHmacService() : super(const FlutterSecureStorage(), null, null);

  @override
  Future<String> getInstallationId() async => 'fake-device-id';
  
  @override
  Future<String> signEvent(DomainEvent event) async => 'fake-signature';
  
  @override
  Future<bool> verifyInstance(DomainEvent event) async => true;
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
