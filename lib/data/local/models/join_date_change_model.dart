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
}
