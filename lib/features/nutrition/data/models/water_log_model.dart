import '../../../../core/data/local/drift/outbox_database.dart' as db;

class WaterLog {
  final String id;
  final String memberId;
  final int amountMl;
  final DateTime timestamp;
  final String? hmacSignature;

  WaterLog({
    required this.id,
    required this.memberId,
    required this.amountMl,
    required this.timestamp,
    this.hmacSignature,
  });

  factory WaterLog.fromDrift(db.WaterLog row) {
    return WaterLog(
      id: row.id,
      memberId: row.memberId,
      amountMl: row.amountMl,
      timestamp: row.timestamp,
      hmacSignature: row.hmacSignature,
    );
  }

  factory WaterLog.fromFirestore(Map<String, dynamic> data) {
    return WaterLog(
      id: data['id'],
      memberId: data['memberId'],
      amountMl: data['amountMl'],
      timestamp: DateTime.parse(data['timestamp']).toLocal(),
      hmacSignature: data['hmacSignature'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'memberId': memberId,
      'amountMl': amountMl,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'hmacSignature': hmacSignature,
    };
  }
}
