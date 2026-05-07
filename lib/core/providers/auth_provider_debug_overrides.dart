import 'package:flutter_riverpod/flutter_riverpod.dart';

final mockUserStoreProvider = Provider<Map<String, String>>((ref) => {});

bool checkMockCredentials(Ref ref, String email, String password, {String? defaultEmail, String? defaultPassword}) {
  bool success = (email == defaultEmail && password == defaultPassword);
  if (!success && ref.read(mockUserStoreProvider).containsKey(email)) {
    success = ref.read(mockUserStoreProvider)[email] == password;
  }
  return success;
}
