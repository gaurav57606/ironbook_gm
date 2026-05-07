import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/owner_repository.dart';
import '../data/local/models/owner_profile_model.dart';
import 'base_providers.dart';

final ownerRepositoryProvider = Provider<IOwnerRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftOwnerRepository(db);
});

final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerProfile?>((ref) {
  final repo = ref.watch(ownerRepositoryProvider);
  return OwnerNotifier(repo);
});

class OwnerNotifier extends StateNotifier<OwnerProfile?> {
  final IOwnerRepository _repo;

  OwnerNotifier(this._repo) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _repo.getOwner();
  }

  Future<void> updateOwner(OwnerProfile profile) async {
    await _repo.upsertOwner(profile);
    state = profile;
  }
}
