import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class JoinDateChange extends HiveObject {
  @HiveField(0)
  late DateTime previousDate;

  @HiveField(1)
  late DateTime newDate;

  @HiveField(2)
  late String reason;

  @HiveField(3)
  late DateTime changedAt;

  JoinDateChange({
    required this.previousDate,
    required this.newDate,
    required this.reason,
    required this.changedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JoinDateChange &&
          runtimeType == other.runtimeType &&
          previousDate == other.previousDate &&
          newDate == other.newDate &&
          reason == other.reason &&
          changedAt == other.changedAt;

  @override
  int get hashCode =>
      previousDate.hashCode ^ newDate.hashCode ^ reason.hashCode ^ changedAt.hashCode;
}









