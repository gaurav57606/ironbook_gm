import 'dart:convert';

/// Utility to produce deterministic JSON strings for HMAC signing.
class CanonicalJson {
  /// Encodes a map into a JSON string with keys sorted alphabetically.
  static String encode(Map<String, dynamic> data) {
    final sortedData = _sortMap(data);
    return jsonEncode(sortedData);
  }

  static Map<String, dynamic> _sortMap(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    final result = <String, dynamic>{};
    for (final key in sortedKeys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        result[key] = _sortMap(value);
      } else if (value is List) {
        result[key] = _sortList(value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  static List _sortList(List list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _sortMap(item);
      } else if (item is List) {
        return _sortList(item);
      }
      return item;
    }).toList();
  }
}
