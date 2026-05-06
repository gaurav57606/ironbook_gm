import 'dart:async';

/// Simplistic memory-backed Fake Firestore for testing sync idempotency.
class FakeFirestore {
  final Map<String, Map<String, dynamic>> _data = {};
  
  bool failNextWrite = false;
  int writeCount = 0;

  Future<void> set(String collection, String id, Map<String, dynamic> data) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw Exception('Simulated Firestore Failure');
    }
    
    writeCount++;
    _data['$collection/$id'] = Map.from(data);
  }

  bool exists(String collection, String id) => _data.containsKey('$collection/$id');
  
  Map<String, dynamic>? get(String collection, String id) => _data['$collection/$id'];

  void clear() {
    _data.clear();
    writeCount = 0;
  }
}


