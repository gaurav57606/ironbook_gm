import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/owner_profile_model.dart';

final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerProfile?>((ref) {
  return OwnerNotifier();
});

class OwnerNotifier extends StateNotifier<OwnerProfile?> {
  OwnerNotifier() : super(null) {
    _init();
  }

  void _init() {
    if (!Hive.isBoxOpen('owner')) return;
    final box = Hive.box<OwnerProfile>('owner');
    state = box.get('owner');
    
    box.listenable().addListener(() {
      state = box.get('owner');
    });
  }

  Future<void> updateOwner(OwnerProfile profile) async {
    final box = Hive.box<OwnerProfile>('owner');
    await box.put('owner', profile);
  }
}
